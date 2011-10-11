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

(** File utils, mostly from Didier Remy's course. *)

open Unix;;

let equal_node n1 n2 =
  n1.st_ino = n2.st_ino && n1.st_dev = n2.st_dev;;

type info = { path : string; lstat : Unix.stats };;
let info path = { path = path; lstat = Unix.lstat path };;

let dir_find f path =
  let dir_handle = Unix.opendir path in
  let rec find () =
    let name = Unix.readdir dir_handle in
    if f name then name else find () in
  try
    Odb_misc.try_finalize find () Unix.closedir dir_handle
  with End_of_file -> raise Not_found
;;

let normalized_path file =
  let rec find_root node =
    let parent_node = info (Filename.concat node.path Filename.parent_dir_name) in
    if equal_node node.lstat parent_node.lstat then "/"
    else
      let found name =
        name <> Filename.current_dir_name && name <> Filename.parent_dir_name &&
        equal_node node.lstat (Unix.lstat (Filename.concat parent_node.path name)) in
      let name = dir_find found parent_node.path in
      Filename.concat (find_root parent_node) name
  in
  match (Unix.stat file).st_kind with
    S_DIR -> find_root (info file)
  | _ ->
      let root = find_root (info (Filename.dirname file)) in
      Filename.concat root (Filename.basename file)
;;
