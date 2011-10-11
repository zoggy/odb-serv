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

(** Server side. *)

(** The name of the server tool (i.e. "server"). If the name
  of the server tool change, using this value will make
  the change transparent. *)
val server_tool : string

(** The server documentation. *)
val server_doc : Odb_doc.tool_doc

(** {2 Handling command line options}

These values can be useful when creating a command-line server.
The {!start_server} function will use {!port} to known which
port to listen to.
 *)

val port : int ref

(** Command line options which can be append to other command
  line options.
  By now, only one option, [-p], allows to set {!port}.*)
val options : (string * Arg.spec * string) list

(** Basic usage message prefix. *)
val usage : string

(** {2 Starting the server} *)

(** [start_server ()] will make the current program a server,
  by listening on port number {!port}.
  @param with_server_tool must be set to [false] when launching
  a secondary server, since the "server" tool is already
  registered in the main server. Default value is [true]. *)
val start_server : ?with_server_tool:bool -> unit -> unit
