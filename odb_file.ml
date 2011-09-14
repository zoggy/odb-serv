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
