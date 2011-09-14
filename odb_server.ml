(** *)

open Unix;;

let server_tool = "server" ;;

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


let rec establish_iterative_server f port =
  let socket_server = open_server port in
  ignore (Sys.signal Sys.sigpipe Sys.Signal_ignore);
  let rec server () =
    prerr_endline "server()";
    begin
      try
        let socket_connection,client_addr = Unix.accept socket_server in
        Unix.setsockopt_float socket_connection SO_RCVTIMEO 10.;
        Unix.setsockopt_float socket_connection SO_SNDTIMEO 10.;
        Printf.eprintf "Connection from %s.\n" (string_of_sockaddr client_addr);
        Pervasives.flush Pervasives.stderr;
        ignore(Thread.create f socket_connection);
      with
      | Unix_error(_,"accept",_) ->
          raise (Failure "establish_iterative_server: accept")
      | Failure msg ->
          prerr_endline msg;
      | e ->
          prerr_endline (Printexc.to_string e);
    end;
    server ()
  in
  server ()
(* /Didier Remy's *)

let com_register_tool options args =
  let (port, resp) =
    if Array.length args <= 0 then
      (None,
       Some (Odb_comm.mk_response ~tool: server_tool ~code: 1
         "missing tool name")
      )
    else if Array.length args <= 1 then
      (None,
       Some (Odb_comm.mk_response ~tool: server_tool ~code: 2
         "missing port number")
      )
    else
      try (Some (int_of_string args.(1)), None)
      with _ ->
        (None,
         Some (Odb_comm.mk_response ~tool: server_tool ~code: 3
           "invalid port number")
        )
  in
  match port, resp with
    None, None -> assert false
  | None, Some resp -> resp
  | Some port, _ ->
     Odb_tools.register_remote_tool args.(0) port;
     let (tools, _) = Odb_tools.get_tools () in
     let tools = Odb_tools.Tool_map.fold
       (fun name _ acc -> name :: acc) tools []
     in
     let tools = String.concat " " tools in
     Odb_comm.mk_response ~tool: server_tool tools
;;

let register_server_tool () =
  let tool = Odb_tools.mk_tool server_tool
    [ "version", (fun _ _ -> Odb_comm.mk_response ~tool: server_tool Odb_config.version) ;
      "register", com_register_tool ;
    ]
  in
  Odb_tools.register_tool tool
;;

let handle_request socket =
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  try
    let rec iter () =
      begin
        try
          let command = Odb_comm.input_command inch in
          let tool = Odb_tools.get_tool command.Odb_comm.com_tool in
          let response = tool.Odb_tools.tool_execute
            command.Odb_comm.com_options command.Odb_comm.com_phrase
          in
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
        | Unix.Unix_error (e, s1, s2) ->
            let msg = Printf.sprintf "%s: %s %s"
              (Unix.error_message e) s1 s2
            in
            let response = Odb_comm.mk_response
              ~tool: "?" ~code: 1 msg
            in
            Odb_comm.output_response ouch response
        end;
        iter ()
      in
      iter ()
  with
  | Odb_comm.Error _msg ->
      Unix.close socket
  | Sys_blocked_io ->
      (try Unix.close socket with _ -> ());
      Thread.exit ()
;;

let port = ref Odb_config.default_port;;

let options = [
    "-p", Arg.Set_int port, "<port> listen on port instead of "^(string_of_int !port) ;

  ];;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let start_server ?(with_server_tool=true) () =
  try
    let tools = ref [] in
    Arg.parse options (fun s -> tools := s :: !tools) usage;
    let tools = List.rev !tools in
    if with_server_tool then register_server_tool ();
    List.iter Odb_tools.load_tool tools;
    ignore(establish_iterative_server handle_request !port)
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;