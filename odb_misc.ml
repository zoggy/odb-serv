(** *)

(*c==v=[Misc.try_finalize]=1.0====*)
let try_finalize f x finally y =
  let res =
    try f x
    with exn -> finally y; raise exn
  in
  finally y;
  res
(*/c==v=[Misc.try_finalize]=1.0====*)

(*c==v=[String.strip_string]=1.0====*)
let strip_string s =
  let len = String.length s in
  let rec iter_first n =
    if n >= len then
      None
    else
      match s.[n] with
        ' ' | '\t' | '\n' | '\r' -> iter_first (n+1)
      | _ -> Some n
  in
  match iter_first 0 with
    None -> ""
  | Some first ->
      let rec iter_last n =
        if n <= first then
          None
        else
          match s.[n] with
            ' ' | '\t' | '\n' | '\r' -> iter_last (n-1)
          |	_ -> Some n
      in
      match iter_last (len-1) with
        None -> String.sub s first 1
      |	Some last -> String.sub s first ((last-first)+1)
(*/c==v=[String.strip_string]=1.0====*)

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

(*c==v=[File.string_of_file]=1.0====*)
let string_of_file name =
  let chanin = open_in_bin name in
  let len = 1024 in
  let s = String.create len in
  let buf = Buffer.create len in
  let rec iter () =
    try
      let n = input chanin s 0 len in
      if n = 0 then
        ()
      else
        (
         Buffer.add_substring buf s 0 n;
         iter ()
        )
    with
      End_of_file -> ()
  in
  iter ();
  close_in chanin;
  Buffer.contents buf
(*/c==v=[File.string_of_file]=1.0====*)

let mtx_protect mtx f s =
  Mutex.lock mtx;
  try_finalize f s Mutex.unlock mtx
;;

type located_message =
  { mes_start : Lexing.position ;
    mes_end : Lexing.position ;
    mes_msg : string ;
  }

let lexing_pos_of_line_char ?(fname="") s line char =
  (*prerr_endline (Printf.sprintf "line=%d, char=%d" line char);*)
  let char = max char 0 in
  let bol = ref 0 in
  let cnum = ref 0 in
  let len = String.length s in
  (*prerr_endline (Printf.sprintf "len(s) = %d" len);
  prerr_endline s;*)
  let linechar = ref 0 in
  let rec iter cur_line pos =
    (*prerr_endline (Printf.sprintf "cur_line=%d, pos=%d, linechar=%d" cur_line pos !linechar);*)
    if pos >= len then invalid_arg "lexing_pos_of_line_char";
    if cur_line >= line && !linechar >= char then
      cnum := pos - 1
    else
      (
       cnum := pos;
       match s.[pos] with
        '\n' ->
           bol := !cnum;
           linechar := 0;
           iter (cur_line+1) (pos+1)
       | _ ->
           incr linechar;
           iter cur_line (pos+1)
      )
  in
  iter 0 0;
  { Lexing.pos_fname = fname ;
    pos_cnum = !cnum ;
    pos_bol = !bol ;
    pos_lnum = line ;
  }
;;

let opt_lexing_pos_of_line_char ?fname s line char =
  try Some (lexing_pos_of_line_char ?fname s line char)
  with _ -> None
;;

let parse_located_messages s =
  let re_start = Str.regexp
    "File \"\\([^\"]*\\)\", line \\([0-9]+\\), char \\(-?[0-9]+\\)\\(-[0-9]+\\)?:\n"
  in
  let len = String.length s in
  let rec iter acc cur_opt pos =
    let p =
      try Some (Str.search_forward re_start s pos)
      with Not_found -> None
    in
    match p with
    | None ->
        begin
          match cur_opt with
            None -> List.rev acc
          | Some lexpos ->
              let msg = strip_string (String.sub s pos (len-pos)) in
              let mes = {
                  mes_start = lexpos ;
                  mes_end = lexpos ;
                  mes_msg = msg ;
                }
              in
              List.rev (mes :: acc)
        end
    | Some p ->
        let (file, line, char) =
          (Str.matched_group 1 s,
           int_of_string (Str.matched_group 2 s),
           int_of_string (Str.matched_group 3 s))
        in
        let next_cur_opt =
          try
            let file_contents = string_of_file file in
            opt_lexing_pos_of_line_char ~fname: file file_contents line char
          with
            _ -> None
        in
        match cur_opt with
          None ->
            iter acc
            next_cur_opt
            (p + String.length (Str.matched_string s))
        | Some lexpos ->
            let msg = strip_string (String.sub s pos (p-pos)) in
            let mes = {
                mes_start = lexpos ;
                mes_end = lexpos ;
                mes_msg = msg ;
              }
            in
            let acc = mes :: acc in
            iter acc next_cur_opt (p + String.length (Str.matched_string s))
  in
  iter [] None 0
;;
