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

type tool =
  { tool_name : string ;
    tool_execute : Odb_comm.command_option list -> string -> Odb_comm.response ;
  }
module Tool_map =
  Map.Make (struct type t = string let compare = compare end)

exception Unknown_tool of string;;

module Unprotected =
  struct
    let tools = ref Tool_map.empty
    let port_by_tool = ref (Tool_map.empty : int Tool_map.t)

    let get_tools () = (!tools, !port_by_tool)
    let set_tools tls port_by_tl =
      tools := tls ; port_by_tool := port_by_tl

    let remove_tool name =
      tools := Tool_map.remove name !tools;
      try
        port_by_tool := Tool_map.remove name !port_by_tool
      with
    Not_found -> ()

    let add_tool_port tool port =
      remove_tool tool.tool_name ;
      port_by_tool := Tool_map.add tool.tool_name port !port_by_tool

    let get_tool name =
      try Tool_map.find name !tools
      with Not_found -> raise (Unknown_tool name)

    let register_tool ?port tool =
      (
       match port with
         None -> ()
       | Some p -> add_tool_port tool p
      );
      tools := Tool_map.add tool.tool_name tool !tools
end;;

let mutex = Mutex.create ();;
let protect f x = Odb_misc.mtx_protect mutex f x;;

let get_tools = protect Unprotected.get_tools;;
let set_tools tls port = protect (Unprotected.set_tools tls) port;;

let get_tool = protect Unprotected.get_tool;;
let register_tool ?port tool =
  protect (Unprotected.register_tool ?port) tool
;;

(* Hack to force the inclusion of terminfo.o (found in libasmrun.lib).
  Thanks to Alain Frisch.*)
external setup : unit -> unit = "caml_terminfo_setup"
let () = if false then setup ()
(* /Hack *)

let () = Dynlink.allow_unsafe_modules true;;
let load_tool filename =
  try Dynlink.loadfile filename
  with Dynlink.Error e ->
      prerr_endline (Dynlink.error_message e)
;;

exception Unknown_command of string;;

let mk_tool name ?doc commands =
  let commands =
    match doc with
      None -> commands
    | Some d ->
        let f  _ _ =
          let html = Odb_doc.html_of_tool_doc d in
          Odb_comm.mk_response ~tool: name html
        in
        ("doc", f) :: commands
  in
  let execute options phrase =
    let command = Odb_commands.command_of_string phrase in
    try
      let f =
        try List.assoc command.(0) commands
        with Not_found -> raise (Unknown_command command.(0))
      in
      f options (Array.sub command 1 ((Array.length command) - 1))
    with Unknown_command com ->
        Odb_comm.mk_response ~tool: name ~code: 1
        (Printf.sprintf "Unknown command \"%s\" for tool \"%s\"" com name)
  in
  { tool_name = name ;
    tool_execute = execute ;
  }
;;

let register_remote_tool name tool_port =
  let sock_mutex = Mutex.create () in
  let connection = ref None in
  let get_connection () =
    match !connection with
      None ->
        let tool_socket = Odb_client.connect "localhost" tool_port in
        connection := Some tool_socket;
        tool_socket
    | Some s -> s
  in
  let execute options phrase =
    let tool_socket = get_connection () in
    let inch = Unix.in_channel_of_descr tool_socket in
    let ouch = Unix.out_channel_of_descr tool_socket in
    Odb_comm.output_command ouch
    (Odb_comm.mk_command ~tool: name ~options phrase);
    let response = Odb_comm.input_response inch in
    response
  in
  let exec options phrase =
    Odb_misc.mtx_protect sock_mutex
    (execute options) phrase
  in
  let tool = { tool_name = name ; tool_execute = exec } in
  prerr_endline ("remote tool registered: "^name);
  register_tool ~port: tool_port tool;
;;

let call ~tool ?(options=[]) phrase =
  try
    let tool = get_tool tool in
    tool.tool_execute options phrase
  with
    Unknown_tool name ->
      { Odb_comm.resp_tool = name ;
        resp_code = 1 ;
        resp_contents = Printf.sprintf "Unregistered tool %s" name ;
      }
;;

let call_and_check ~tool ?options phrase =
  Odb_comm.check_response (call ~tool ?options phrase)
;;
