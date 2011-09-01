(** *)

open Unix;;

let server_tool = "server" ;;
let client_sockets = ref [];;

(* Most of this code from Didier Remy's course *)
let try_finalize f x finally y =
  let res = try f x with exn -> finally y; raise exn in
  finally y;
  res;;

let open_server port =
  try
    let socket = Unix.socket PF_INET SOCK_STREAM 0 in
    Unix.setsockopt socket SO_REUSEADDR true;
    Unix.bind socket (ADDR_INET (Unix.inet_addr_any, port));
    Unix.listen socket 20;
    socket
  with _ ->
    let message = Printf.sprintf "open_server %d: can't open" port in
    raise (Failure message);;

let string_of_sockaddr s = match s with
  | ADDR_UNIX s -> s
  | ADDR_INET (inet,p) -> (Unix.string_of_inet_addr inet)^":"^(string_of_int p);;


let remove_closed_sockets socket_server =
  prerr_endline "removing closed sockets";
  let is_ok s =
    try ignore(Unix.select [s] [] [] 0.); true
    with Unix.Unix_error (_,"select",_) ->
        false
  in
  client_sockets := List.filter is_ok !client_sockets;
  Odb_tools.Socket_map.iter
  (fun socket name ->
     if is_ok socket then () else Odb_tools.remove_tool name)
  !Odb_tools.tool_by_socket;
  if not (is_ok socket_server) then
    begin
      prerr_endline "Fatal error: Server socket is closed";
      exit 1
    end
;;

let rec establish_iterative_server f port =
  let socket_server = open_server port in
  ignore (Sys.signal Sys.sigpipe Sys.Signal_ignore);
  let rec select () =
    let in_sockets =
      socket_server :: !client_sockets @
      (Odb_tools.Socket_map.fold
       (fun s _ acc -> s :: acc) !Odb_tools.tool_by_socket []
        )
    in
    try Unix.select in_sockets [] [] (-1.0)
    with Unix.Unix_error (Unix.EINTR,_,_) -> select ()
  in
  let rec server () =
    prerr_endline "server()";
    begin
      try
        let (in_ready,_,_) = select () in
        match in_ready with
          [] -> ()
        | s :: _ ->
            if s = socket_server then
              begin
                let socket_connection,client_addr = Unix.accept socket_server in
                Unix.setsockopt_float socket_connection SO_RCVTIMEO 10.;
                Unix.setsockopt_float socket_connection SO_SNDTIMEO 10.;
                Printf.eprintf "Connection from %s.\n" (string_of_sockaddr client_addr);
                Pervasives.flush Pervasives.stderr;
                client_sockets := socket_connection :: !client_sockets ;
                f socket_connection;
              end
            else
              f s
      with
      | Unix_error(_,"accept",_) ->
          raise (Failure "establish_iterative_server: accept")
      | Unix_error(_,"select",_) ->
          (** A socket was closed, let's find it and remove it *)
          remove_closed_sockets socket_server;
      | Failure msg ->
          prerr_endline msg;
          prerr_endline
          (Printf.sprintf "client_sockets: %d\ntool_sockets: %d"
           (List.length !client_sockets)
           (Odb_tools.Socket_map.cardinal !Odb_tools.tool_by_socket)
          );
      | e ->
          prerr_endline (Printexc.to_string e);
    end;
    server ()
  in
  server ()
(* /Didier Remy's *)


let com_close socket _ _ =
  if List.mem socket !client_sockets then
    (
     client_sockets := List.filter ((<>) socket) !client_sockets;
     Unix.shutdown socket SHUTDOWN_ALL;
     Unix.close socket
    )
  else
    (
     try
       let name = Odb_tools.Socket_map.find socket !Odb_tools.tool_by_socket in
       Odb_tools.remove_tool name
       (* which closes the socket too *)
     with
       Not_found ->
         (* the new connection is just to close the socket :-) *)
         Unix.shutdown socket SHUTDOWN_ALL;
         Unix.close socket
    );
  None
;;

let com_register_tool socket options args =
  if Array.length args <= 0 then
    Some
    (Odb_comm.mk_response ~tool: server_tool ~code: 1
     "missing tool name")
  else
    (
     (* remove the connection from client sockets and add it
       to tool sockets *)
     client_sockets := List.filter ((<>) socket) !client_sockets;
     Odb_tools.register_remote_tool args.(0) socket;
     None
    )
;;

let register_server_tool () =
  let tool = Odb_tools.mk_tool server_tool
    [ "version", (fun _ _ _ -> Some (Odb_comm.mk_response ~tool: server_tool Odb_config.version)) ;
      "register", com_register_tool ;
    ]
  in
  Odb_tools.register_tool tool
;;

let handle_request socket =
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  try
    try
      let command = Odb_comm.input_command inch in
      let tool = Odb_tools.get_tool command.Odb_comm.com_tool in
      let response = tool.Odb_tools.tool_execute
        socket command.Odb_comm.com_options command.Odb_comm.com_phrase
      in
      match response with
      None -> ()
      | Some response ->
          Odb_comm.output_response ouch response;
    with
      Odb_tools.Unknown_tool name ->
        let response =
          { Odb_comm.resp_tool = name ;
            resp_code = 1 ;
            resp_contents = Printf.sprintf "Unregistered tool %s" name ;
          }
        in
        Odb_comm.output_response ouch response
    | Failure msg ->
        let response = Odb_comm.mk_response
          ~tool: "?" ~code: 1 msg
        in
        Odb_comm.output_response ouch response
  with
  | Odb_comm.Error msg ->
      Unix.close socket
;;

let port = ref Odb_config.default_port;;

let options = [
    "-p", Arg.Set_int port, "<port> listen on port instead of "^(string_of_int !port) ;

  ];;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let start_server () =
  try
    let tools = ref [] in
    Arg.parse options (fun s -> tools := s :: !tools) usage;
    let tools = List.rev !tools in
    register_server_tool ();
    List.iter Odb_tools.load_tool tools;
    ignore(establish_iterative_server handle_request !port)
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;