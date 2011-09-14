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
let file = Sys.argv.(1);;
let s = string_of_file file;;
let l = Odb_misc.parse_located_messages s;;
open Odb_misc;;

let f mes =
  prerr_endline
  (Printf.sprintf "File \"%s\", line %d, character %d:\n%s"
   mes.mes_start.Lexing.pos_fname
   mes.mes_start.Lexing.pos_lnum
   (mes.mes_start.Lexing.pos_cnum - mes.mes_start.Lexing.pos_bol)
   mes.mes_msg
  )
;;
List.iter f l;;