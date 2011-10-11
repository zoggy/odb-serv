(*********************************************************************************)
(*                Odb-server                                                     *)
(*                                                                               *)
(*    Copyright (C) 2011 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License as                    *)
(*    published by the Free Software Foundation; either version 2 of the         *)
(*    License.                                                                   *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public                  *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    As a special exception, you have permission to link this program           *)
(*    with the OCaml compiler and distribute executables, as long as you         *)
(*    follow the requirements of the GNU GPL in regard to all of the             *)
(*    software in the executable aside from the OCaml compiler.                  *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*********************************************************************************)

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
  let tool_spec = Str.regexp "^\\([a-zA-z_-]+\\):" in
  let (tool, phrase) =
    try
      let p = Str.search_forward tool_spec phrase 0 in
      let tool = Str.matched_group 1 phrase in
      let p = p + String.length tool + 1 in
      (tool, String.sub phrase p (String.length phrase - p))
    with
      Not_found -> (!tool, phrase)
  in
  Odb_comm.output_command ouch (Odb_comm.mk_command ~tool phrase);
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