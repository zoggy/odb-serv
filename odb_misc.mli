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

(** Utilities. *)

(*i==v=[Misc.try_finalize]=1.0====*)
(** [try_finalize f x g y] applies [f] to [x] and return
   the result or raises an exception, but in all cases
   [g] is applied to [y] before returning or raising the exception.
@author Didier Rémy
@version 1.0
@cgname Misc.try_finalize*)
val try_finalize : ('l -> 'm) -> 'l -> ('n -> unit) -> 'n -> 'm
(*/i==v=[Misc.try_finalize]=1.0====*)


(*i==v=[String.strip_string]=1.0====*)
(** [strip_string s] removes all leading and trailing spaces from the given string.
@author Maxence Guesdon
@version 1.0
@cgname String.strip_string*)
val strip_string : string -> string
(*/i==v=[String.strip_string]=1.0====*)


(*i==v=[String.split_string]=1.1====*)
(** Separate the given string according to the given list of characters.
@author Maxence Guesdon
@version 1.1
@param keep_empty is [false] by default. If set to [true],
   the empty strings between separators are kept.
@cgname String.split_string*)
val split_string : ?keep_empty:bool -> string -> char list -> string list
(*/i==v=[String.split_string]=1.1====*)


(*i==v=[File.string_of_file]=1.0====*)
(** [string_of_file filename] returns the content of [filename]
   in the form of one string.
@author Maxence Guesdon
@version 1.0
@raise Sys_error if the file could not be opened.
@cgname File.string_of_file*)
val string_of_file : string -> string
(*/i==v=[File.string_of_file]=1.0====*)


(** A message with a location. Useful to transfer location and name of
  OCaml expressions. *)
type located_message =
  { mes_start : Lexing.position ;
    mes_end : Lexing.position ;
    mes_msg : string ;
  }

(** [mtx_protect mutex f x] applies [f] to [x]
  in the critical section protected by [mutex]. If [f] fails,
  the mutex in unlocked and the exception re-raised. *)
val mtx_protect : Mutex.t -> ('a -> 'b) -> 'a -> 'b

(** Return a list of {!located_message} from the given string.
  Bad locations in the string are ignored (example: a location
  refering to a non-exising position in a file, or refering
  to a non-existing file.
*)
val parse_located_messages : string -> located_message list
