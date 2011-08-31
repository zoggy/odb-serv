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
    server () in
  try server () with
    Unix_error(_,"accept",_) ->
      raise (Failure "establish_iterative_server: accept")
  | _ ->  raise (Failure "Unexpected Error")
(* /This code *)

let handle_request socket =
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  let command = Comm.input_command inch in
  try
    let tool = Tools.get_tool command.Comm.com_tool in
    let response = tool.Tools.tool_execute
      command.Comm.com_options command.Comm.com_phrase
    in
    Comm.output_response ouch response
  with
    Tools.Unknown_tool name ->
      let response =
        { Comm.resp_tool = name ;
          resp_code = 1 ;
          resp_contents = Printf.sprintf "Unregistered tool %s" name ;
        }
      in
      Comm.output_response ouch response
;;

let handle_connection socket =
  try_finalize handle_request socket close socket
;;


let port = ref 15007;;

let options = [
    "-p", Arg.Set_int port, "<port> listen on port instead of "^(string_of_int !port) ;

  ];;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let () =
  try
    let tools = ref [] in
    Arg.parse options (fun s -> tools := s :: !tools) usage;
    let tools = List.rev !tools in
    List.iter Tools.load_tool tools;
    ignore(establish_iterative_server handle_request !port)
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;
  