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

let register_to_server tool_name client_port host port =
  let socket = connect host port in
  let ouch = Unix.out_channel_of_descr socket in
  let inch = Unix.in_channel_of_descr socket in
  let com = Odb_comm.mk_command
    ~tool: "server" (Printf.sprintf "register %s %d" tool_name client_port)
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
 