(** Test client *)

let port = ref Odb_config.default_port ;;
let tool = ref "server";;
let host = ref "localhost";;
let multiple_connections = ref false;;

let options = [
    "-p", Arg.Set_int port, "<port> connect on port instead of "^(string_of_int !port) ;
    "-t", Arg.Set_string tool, "<tool> speak to <tool> instead of \""^ !tool ^"\"" ;
    "-h", Arg.Set_string host, "<host> connect to <host> instead of "^ !host ;
    "-m", Arg.Clear multiple_connections, " make a new connection to server for each phrase";
  ];;


let execute_phrase inch ouch phrase =
  Odb_comm.output_command ouch (Odb_comm.mk_command ~tool: !tool phrase);
  let resp = Odb_comm.input_response inch in
  print_endline resp.Odb_comm.resp_contents
;;

let connect_and_execute_phrase host port phrase =
  let socket = Odb_client.connect host port in
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  execute_phrase inch ouch phrase;
  Unix.close socket
;;

let execute_on_one_connection host port phrases =
  let socket = Odb_client.connect host port in
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  List.iter (execute_phrase inch ouch) phrases;
  Unix.close socket
;;

let usage = Printf.sprintf "Usage: %s [options] phrases\nwhere options are:" Sys.argv.(0);;

let () =
  try
    let phrases = ref [] in
    Arg.parse options (fun s -> phrases := s :: !phrases) usage;
    let phrases = List.rev !phrases in
    if !multiple_connections then
      List.iter (connect_and_execute_phrase !host !port) phrases
    else
      execute_on_one_connection !host !port phrases
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;