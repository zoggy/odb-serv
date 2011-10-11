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

(** Communications. *)

(** {2 Commands} *)

(** A command option is of the form [(key, value]). *)
type command_option = string * string

(** A command refers to a tool name, optional command options, and the
  phrase to execute. *)
type command = {
  com_tool : string;
  com_options : command_option list;
  com_phrase : string;
}

(** Convenient function to create a {!command} structure. *)
val mk_command :
  tool:string -> ?options:command_option list -> string -> command

(** This exception is raised when an error occurs when sending or
     receiving data. Syntax errors in command or response raise
     a [Failure] exception.*)
exception Error of string

(** Read a command from channel. *)
val input_command : in_channel -> command

(** Write a command to a channel. *)
val output_command : out_channel -> command -> unit

(** {2 Responses} *)

(** A response refers to a tool name in field [resp_tool].
  The [resp_contents] field contains the error message if
  the [resp_code <> 0] or else the contents of the response. *)
type response = {
  resp_tool : string;
  resp_code : int;
  resp_contents : string;
}

(** Convenient function to create a {!response} structure.
  Default code is [0]. *)
val mk_response : tool:string -> ?code:int -> string -> response

(** Read a response from a channel. *)
val input_response : in_channel -> response

(** Write a response to a channel. *)
val output_response : out_channel -> response -> unit

(** [check_response r] raises [Failure r.resp_contents] if
  [r.resp_code <> 0], else return [r.resp_contents].*)
val check_response : response -> string
