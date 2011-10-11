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

(** Client side (i.e. secondary server).

 A secondary server is also a client for the main server.
 *)

(** [register_to_server tool_name local_port remote_host remote_port]
  register the givne tool of the current program to the main server
  specified by [remote_host] and [remote_port]. By now, remote_host should
  be ["localhost"] as secondary servers and main server can not be
  on different hosts. The [local_port] is the port of the current program,
  which the main server should connect back to when needing to call the
  tool [tool_name].
  The function returns a connection to the server and the list of
  tools that the server knows, so that the current program can
  register these tools as remote tools (after filtering its own tools).
*)
val register_to_server :
  string -> int -> string -> int -> Unix.file_descr * string list

(** {2 Low level functions} *)

val open_connection : Unix.inet_addr -> int -> Unix.file_descr
val inet_addr_of_name : string -> Unix.inet_addr
val connect : string -> int -> Unix.file_descr
