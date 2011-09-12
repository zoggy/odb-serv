{
(** The lexer for project files. *)

open Lexing;;
open Odb_project_parser;;

let error lexbuf msg =
  let pos = lexbuf.Lexing.lex_curr_p in
  let msg = Printf.sprintf "file %s, line %d, character %d"
    (Filename.quote lexbuf.lex_start_p.pos_fname)
    lexbuf.lex_start_p.pos_lnum
    (lexbuf.lex_start_p.pos_cnum - lexbuf.lex_start_p.pos_bol)
  in
  failwith msg
;;

let string_buffer = Buffer.create 256 ;;
}

let newline = ('\010' | '\013' | "\013\010")
let blank = [' ' '\009' '\012']
let any = [^'\n']*

let id_char = ['a'-'z' 'A'-'Z' '0'-'9' '_' '.' '/']
let var_char = ['a'-'z' 'A'-'Z' '0'-'9' '_']
let var_ref = "$("var_char+')'
let id = ((id_char+)|var_ref)+


rule main = parse
| '"' { Buffer.reset string_buffer; string lexbuf }
| id { Id (Lexing.lexeme lexbuf) }
| "+=" { PLUSEQUAL }
| "-=" { MINUSEQUAL }
| "=" { EQUAL }
| newline { Lexing.new_line lexbuf; main lexbuf }
| ':' { COLON }
| '{' { LBRACE }
| '}' { RBRACE }
| blank { main lexbuf }
| eof { EOF }
| _ { error lexbuf (Printf.sprintf "Invalid character %s" (Lexing.lexeme lexbuf)) }

and string = parse
 "\\\""  { Buffer.add_char string_buffer '"'; string lexbuf }
| "\\\\" { Buffer.add_char string_buffer '\\'; string lexbuf }
| '"'  { String (Buffer.contents string_buffer) }
| '\n' {
      let module L = Lexing in
      Buffer.add_string string_buffer (Lexing.lexeme lexbuf);
      Lexing.new_line lexbuf;
      string lexbuf
    }
| _ { Buffer.add_string string_buffer (Lexing.lexeme lexbuf); string lexbuf }
| eof { error lexbuf "String not terminated." }
