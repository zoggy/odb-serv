(** *)

open Unix;;

(* This code from Didier Remy's course *)

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
    let socket_connection,client_addr = Unix.accept socket_server in
    Unix.setsockopt_float socket_connection SO_RCVTIMEO 10.;
    Unix.setsockopt_float socket_connection SO_SNDTIMEO 10.;
    Printf.eprintf "Connection from %s.\n" (string_of_sockaddr client_addr);
    Pervasives.flush Pervasives.stderr;

    f socket_connection;
    server ()
  in
  try server () with
    Unix_error(_,"accept",_) ->
      raise (Failure "establish_iterative_server: accept")
  | Failure msg ->
      prerr_endline msg;
      server ()
  | e ->
      prerr_endline (Printexc.to_string e);
      server ()
(* /This code *)

let register_server_tool () =
  let tool = "server" in
  let tool = Odb_tools.mk_tool tool
    ["version", (fun _ -> Odb_comm.mk_response ~tool Odb_config.version)]
  in
  Odb_tools.register_tool tool
;;

let handle_request socket =
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  let command = Odb_comm.input_command inch in
  try
    let tool = Odb_tools.get_tool command.Odb_comm.com_tool in
    let response = tool.Odb_tools.tool_execute
      command.Odb_comm.com_options command.Odb_comm.com_phrase
    in
    Odb_comm.output_response ouch response;
    Pervasives.close_out ouch
  with
    Odb_tools.Unknown_tool name ->
      let response =
        { Odb_comm.resp_tool = name ;
          resp_code = 1 ;
          resp_contents = Printf.sprintf "Unregistered tool %s" name ;
        }
      in
      Odb_comm.output_response ouch response;
      Pervasives.close_out ouch
;;

let handle_connection socket =
  try_finalize handle_request socket close socket
;;


let port = ref Odb_config.default_port;;

let options = [
    "-p", Arg.Set_int port, "<port> listen on port instead of "^(string_of_int !port) ;

  ];;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let () =
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
  