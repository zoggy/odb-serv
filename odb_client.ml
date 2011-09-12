(** *)

open Unix;;

(* Code from Didier Remy's course *)
let open_connection address port =
  try
    let socket = Unix.socket PF_INET SOCK_STREAM 0 in
    Unix.connect socket (ADDR_INET (address,port));
    socket
  with _ ->
    let addr = Unix.string_of_inet_addr address in
    let message =
      Printf.sprintf "open_connection %s %d : unable to connect" addr port in
    raise (Failure message);;

(** Conversion d'une chaîne de caratères en adresse Internet *)
let inet_addr_of_name machine =
  try
    (Unix.gethostbyname machine).h_addr_list.(0)
  with _ ->
    try
      Unix.inet_addr_of_string machine
    with _ ->
      let message =
        Printf.sprintf "inet_addr_of_name %s : unknown machine" machine in
      raise (Failure message);;
(* /Didier Remy *)

let connect host port =
  try
    let addr = inet_addr_of_name host in
    open_connection addr port
  with
  Unix.Unix_error (e, s1, s2) ->
      let msg = Printf.sprintf "%s: %s %s"
        (Unix.error_message e) s1 s2
      in
      failwith msg
;;

let register_to_server tool_name host port =
  let socket = connect host port in
  let ouch = Unix.out_channel_of_descr socket in
  let inch = Unix.in_channel_of_descr socket in
  let com = Odb_comm.mk_command
    ~tool: "server" (Printf.sprintf "register %s" tool_name)
  in
  Odb_comm.output_command ouch com;
  let resp = Odb_comm.input_response inch in
  if resp.Odb_comm.resp_code <> 0 then
    failwith resp.Odb_comm.resp_contents
  else
    (
    let tools = Odb_misc.split_string resp.Odb_comm.resp_contents [' '] in
    (socket, tools)
    )
;;
 