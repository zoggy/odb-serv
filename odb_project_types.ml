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

type opn = Set | Plus | Minus;;
type vardef = string * opn * string;;
type rule = string list * vardef list;;

type phrase = Vardef of vardef | Rule of rule;;

module SMap = Map.Make
  (struct type t = string let compare = Pervasives.compare end);;

type env = {
  env_vars : string SMap.t ;
  env_targets : (string SMap.t) SMap.t ;
};;


let empty_env =
  { env_vars = SMap.empty ;
    env_targets = SMap.empty ;
  }
;;

(** [add_vars env1 vars] add [vars] to [env1.env_vars], enventually
  masking existing associations. *)
let add_vars env1 vars =
  let v =
    SMap.fold SMap.add
    vars
    env1.env_vars
  in
  { env1 with env_vars = v }
;;

let get_value env var = SMap.find var env.env_vars ;;
