(** *)

open Odb_project_types;;

let tool_name = "project";;

let check_nb_args args n =
  if Array.length args < n then
    failwith
    (Printf.sprintf
     "Missing arguments: %d instead of %d required"
     (Array.length args)
     n
    )
;;

module SMap = Map.Make
  (struct type t = string let compare = compare end);;

let projects = ref SMap.empty;;

let mutex = Mutex.create ();;
let protect f x = Odb_misc.mtx_protect mutex f x;;

let set_projects f =
  protect (fun () -> projects := f !projects) ()
;;

let projects = protect (fun () -> !projects);;

let normalize_targets project_dir env =
  let f target map acc =
    let target2 =
      if Filename.is_relative target then
        Odb_file.normalized_path (Filename.concat project_dir target)
      else
        target
    in
    prerr_endline (Printf.sprintf "target: %s -> %s" target target2);
    Odb_project_types.SMap.add target2 map acc
  in
  let targets = Odb_project_types.SMap.fold f
    env.env_targets Odb_project_types.SMap.empty
  in
  { env with env_targets = targets }
;;

let load_project file =
  let f = file in
  let file = Odb_file.normalized_path file in
  prerr_endline (Printf.sprintf "normalize: %s -> %s" f file);
  let project_dir = Filename.dirname file in
  let phrases = Odb_project.parse_project_file file in
  let env = Odb_project.build_env phrases in
  let env = normalize_targets project_dir env in
  set_projects (SMap.add file env)
;;

(** Look for the project of a given absolute filename.
  We look for the first project whose file
  description is in the same directory or
  in a directory "above" the given file.
  If there are more than one, we choose the one
  with the longest path. *)
let project_by_file ref_file =
  let projects = projects () in
  let ref_file = Odb_file.normalized_path ref_file in
  let f proj_file env acc =
   let dir_proj = Filename.dirname proj_file in
   let len_proj = String.length dir_proj in
   if String.length ref_file >= len_proj &&
     (String.sub ref_file 0 len_proj = dir_proj)
    then
      match acc with
        None -> Some (proj_file, env)
      | Some (acc_proj_file, _) ->
          if String.length (Filename.dirname acc_proj_file) >= len_proj then
            acc
          else
            Some (proj_file, env)
    else
      acc
  in
  SMap.fold f projects None
;;

let response msg = Odb_comm.mk_response ~tool: tool_name msg;;
let err_response code msg =
  Odb_comm.mk_response ~tool: tool_name ~code msg;;

let com_load_project options args =
  check_nb_args args 1;
  try
    load_project args.(0);
    response "OK"
  with Failure msg -> err_response 1 msg
;;

let no_project_response file =
  err_response 1
  (Printf.sprintf "No project found for file %s" file)
;;

let com_get_var options args =
  check_nb_args args 2;
  let file = args.(0) in
  let var = args.(1) in
  match project_by_file file with
    None -> no_project_response file
  | Some (_, env) ->
      let v =
        try Odb_project_types.get_value env var
        with Not_found -> ""
      in
      response v
;;

let com_targets options args =
  check_nb_args args 1;
  let file = args.(0) in
  match project_by_file file with
    None -> no_project_response file
  | Some (_, env) ->
      let targets = Odb_project_types.SMap.fold
        (fun k _ acc -> (Filename.quote k) :: acc)
        env.env_targets []
      in
      let s = String.concat " " targets in
      response s
;;

let com_attribute options args =
  check_nb_args args 2;
  let file = args.(0) in
  let attr = args.(1) in
  match project_by_file file with
    None -> no_project_response file
  | Some (_, env) ->
      let map_opt =
        try Some (Odb_project_types.SMap.find file env.env_targets)
        with Not_found -> None
      in
      match map_opt with
        None -> err_response 1 (Printf.sprintf "no target %s" file)
      | Some map ->
          let v =
            try Odb_project_types.SMap.find attr map
            with Not_found -> ""
          in
          response v
;;

let com_project_dir options args =
  check_nb_args args 1;
  let file = args.(0) in
  match project_by_file file with
    None -> no_project_response file
  | Some (f,_) -> response (Filename.dirname f)
;;

let tool = Odb_tools.mk_tool tool_name
  [ "get", com_get_var ;
    "load", com_load_project ;
    "targets", com_targets ;
    "attribute", com_attribute ;
    "projectdir", com_project_dir ;
  ]
;;
