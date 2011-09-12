(** *)

open Odb_project_types;;
module SMap = Odb_project_types.SMap;;

(*c==v=[String.split_string]=1.1====*)
let split_string ?(keep_empty=false) s chars =
  let len = String.length s in
  let rec iter acc pos =
    if pos >= len then
      match acc with
        "" -> []
      | _ -> [acc]
    else
      if List.mem s.[pos] chars then
        match acc with
          "" ->
            if keep_empty then
              "" :: iter "" (pos + 1)
            else
              iter "" (pos + 1)
        | _ -> acc :: (iter "" (pos + 1))
      else
        iter (Printf.sprintf "%s%c" acc s.[pos]) (pos + 1)
  in
  iter "" 0
(*/c==v=[String.split_string]=1.1====*)

let parse parse_fun lexbuf =
  try parse_fun Odb_project_lexer.main lexbuf
  with
    e ->
      let msg =
        match e with
          Failure s -> s
        | Parsing.Parse_error ->
          Odb_project_lexer.error lexbuf "Parse error"
        | e -> Printexc.to_string e
      in
      failwith msg
;;

let parse_project = parse Odb_project_parser.phrases;;

let parse_project_file file =
  let lexbuf = Lexing.from_channel (open_in file) in
  parse_project lexbuf;;

let parse_project_string s =
  let lexbuf = Lexing.from_string s in
  parse_project lexbuf;;

let rec subst_vars env s =
  let re = Str.regexp ".?\\$(\\([a-zA-Z0-9_]+\\))" in
  let f matched =
    if matched.[0] = '\\' then
      (String.sub matched 1 ((String.length matched) - 1))
    else
      begin
        let start = if matched.[0] = '$' then 0 else 1 in
        let name = Str.matched_group 1 s in
        let s2 =
          try SMap.find name env.env_vars
          with Not_found ->
              failwith (Printf.sprintf "Unbound var '%s'" name)
        in
        let s =
          Printf.sprintf "%s%s"
          (String.sub matched 0 start)
          s2
        in
        subst_vars env s
      end
  in
  Str.global_substitute re f s
;;

let ids_of_strings l =
  let s = String.concat " " l in
  split_string s [' ' ; '\t' ; '\r' ; '\n']
;;

let set env name s =
  { env with env_vars = SMap.add name s env.env_vars }
;;

let plus env name s =
  try
    let s2 = SMap.find name env.env_vars in
    set env name (s2^s)
  with Not_found -> set env name s
;;

let minus env name s =
  try
    let s2 = SMap.find name env.env_vars in
    let re = Str.regexp_string s in
    let s2 = Str.global_replace
      re "" s2
    in
    set env name s2
  with Not_found -> set env name ""
;;


let eval_var_def env ?(env0=env) id opn s =
  let s = subst_vars env0 s in
  let f env id =
    match opn with
      Set -> set env id s
    | Plus -> plus env id s
    | Minus -> minus env id s
  in
  List.fold_left
    f env (ids_of_strings [subst_vars env0 id])
;;

let eval_phrase env = function
  Vardef (id, opn, s) ->
    eval_var_def env id opn s

| Rule (ids, vardefs) ->
    let ids = ids_of_strings
      (List.map (subst_vars env) ids)
    in
    let eval_def ~env0 env_id (id, opn, s) =
      let env0 = Odb_project_types.add_vars env0 env_id.env_vars in
      eval_var_def ~env0 env_id id opn s
    in
    let f env id =
      let vars_id =
        try SMap.find id env.env_targets
        with Not_found -> SMap.empty
      in
      let env_id =
        { Odb_project_types.empty_env with
          env_vars = vars_id ;
        }
      in
      let env_id2 = List.fold_left (eval_def ~env0: env) env_id vardefs in

      { env with
        env_targets = SMap.add id env_id2.env_vars env.env_targets
      }
    in
    List.fold_left f env ids
;;

let build_env phrases =
  List.fold_left eval_phrase
    Odb_project_types.empty_env phrases
;;

let print_env env =
  let b = Buffer.create 256 in
  let f ?(margin="") id s =
    Printf.bprintf b "%s%s=\"%s\"\n" margin id s
  in
  let g id map =
    Printf.bprintf b "%s:\n" id;
    SMap.iter (f ~margin: "  ") map
  in
  SMap.iter f env.env_vars;
  SMap.iter g env.env_targets;
  Buffer.contents b
;;
