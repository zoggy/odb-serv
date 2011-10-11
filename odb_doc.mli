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

(** Documenting tools. *)

(** Documentation of a command. *)
type command_doc = {
  com_name : string; (** Name of the command, e.g.: [get] *)
  com_synopsis : string; (** Synopsis, e.g.: [get <file> <var>] *)
  com_doc : string; (** Documentation (valid XHTML); keep it simple ! *)
}

(** Documentation of a tool. *)
type tool_doc =
  { tool_doc : string;  (** Introduction about the tool. *)
    tool_coms : command_doc list;  (** Documentation of commands. *)
  }

(** {2 Generating XHTML from documentation specification} *)

val escape_html : string -> string
val html_of_command_doc : Buffer.t -> command_doc -> unit
val html_of_tool_doc : tool_doc -> string
val css_style : string
val html_header : string
val html_page : (string * string) list -> string
