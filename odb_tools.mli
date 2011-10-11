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

(** Tools *)

(** A tool is just a name and a function to execute commands. *)
type tool = {
  tool_name : string;
  tool_execute : Odb_comm.command_option list -> string -> Odb_comm.response;
    (** [tool_execute options command] will execute the given phrase and
       return a response. The options are the ones given with the
       tool name in a command (see {!Odb_comm.command}). *)
}

(** Exception raised when trying to get a non-registered tool. *)
exception Unknown_tool of string

module Tool_map : Map.S with type key = string;;

(** [protect f x] locks the tool information, compute [f x]
  and release the lock. The lock is released even if an exception
  is raised by [f x].*)
val protect : ('a -> 'b) -> 'a -> 'b

(** {b The following functions use {!protect} when accessing tool information.} *)

(** [get_tools ()] return the pairs [(tools, ports)] where [tools] maps
  tool name to tool information, while [ports] maps a tool name
  to the local port to connect to, in case the tool is a remote port. *)
val get_tools : unit -> tool Tool_map.t * int Tool_map.t

(** [set_tools tools ports] set information about the tools. See
  {!get_tools}.*)
val set_tools : tool Tool_map.t -> int Tool_map.t -> unit

(** Get a tool by its name, or raise [Unknown_tool tool_name] is the
  tool is not registered. *)
val get_tool : string -> tool

(** [register_tool ?port tool] register the given tool in the tool maps.
  If a previous tool with the same name was already registered, it is
  replaced by the new one.
*)
val register_tool : ?port:int -> tool -> unit

(** [load_tool file] loads the given ocaml object file using [Dynlink]. This
  function is used to load plugin tools. *)
val load_tool : string -> unit


(** Exception raised when executing a command which does not exist
  for a given tool. *)
exception Unknown_command of string

(** [mk_tool name spec] is a convenient function to create a tool
  called [name].
  [spec] is a list of [(command, f)] where [command] is the name of
  a tool command (that is the first word of a phrase to execute) and
  [f] is the function to execute when a phrase begins by this command name.
  @param doc can be used to automatically add a "doc" command to the tool,
  returning the documentation of the tool in the correct format, using
  {!Odb_doc.html_of_tool_doc}.*)
val mk_tool :
  string ->
  ?doc:Odb_doc.tool_doc ->
  (string *
   (Odb_comm.command_option list -> string array -> Odb_comm.response))
  list -> tool

(** Registering a remote tool specified by its name and the
  local port to connect to. The first call to this tool will
  initialize a connection to the remote port. Then the current
  server will act as a proxy for the tool on the remote server.*)
val register_remote_tool : string -> int -> unit

(** [call name ?options phrase] make the given tool execute the given [phrase]
  and return the response. *)
val call :
  tool:Tool_map.key ->
  ?options:Odb_comm.command_option list -> string -> Odb_comm.response

(** Same as {!call} but if the response has a non-zero error code,
  then raise [Failure msg] where [msg] is the response contents.
  Else return the response contents.*)
val call_and_check :
  tool:Tool_map.key ->
  ?options:Odb_comm.command_option list -> string -> string
