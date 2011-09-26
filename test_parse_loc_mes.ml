let file = Sys.argv.(1);;
let s = Odb_misc.string_of_file file;;
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