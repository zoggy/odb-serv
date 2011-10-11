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

{
(** The lexer for project files. *)

open Lexing;;
open Odb_project_parser;;

let error lexbuf msg =
  let pos = lexbuf.Lexing.lex_curr_p in
  let msg = Printf.sprintf "file %s, line %d, character %d"
    (Filename.quote pos.pos_fname)
    pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol)
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
