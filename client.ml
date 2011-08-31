(** Test client *)

let port = ref Config.default_port ;;
let tool = ref "server";;
let host = ref "localhost";;

let options = [
    "-p", Arg.Set_int port, "<port> connect on port instead of "^(string_of_int !port) ;
    "-t", Arg.Set_string tool, "<tool> speak to <tool> instead of \""^ !tool ^"\"" ;
    "-h", Arg.Set_string host, "<host> connect to <host> instead of "^ !host ;
  ];;




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

let execute_phrase host port tool phrase =
  let socket = connect host port in
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  Comm.output_command ouch (Comm.mk_command ~tool phrase);
  let resp = Comm.input_response inch in
  print_endline resp.Comm.resp_contents;
  Unix.close socket
;;

let usage = Printf.sprintf "Usage: %s [options] phrases\nwhere options are:" Sys.argv.(0);;

let () =
  try
    let phrases = ref [] in
    Arg.parse options (fun s -> phrases := s :: !phrases) usage;
    let phrases = List.rev !phrases in
    List.iter (execute_phrase !host !port !tool) phrases
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;