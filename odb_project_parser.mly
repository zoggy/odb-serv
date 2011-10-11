/*********************************************************************************/
/*                Odb-server                                                     */
/*                                                                               */
/*    Copyright (C) 2011 Institut National de Recherche en Informatique          */
/*    et en Automatique. All rights reserved.                                    */
/*                                                                               */
/*    This program is free software; you can redistribute it and/or modify       */
/*    it under the terms of the GNU General Public License as                    */
/*    published by the Free Software Foundation; either version 2 of the         */
/*    License.                                                                   */
/*                                                                               */
/*    This program is distributed in the hope that it will be useful,            */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of             */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              */
/*    GNU Library General Public License for more details.                       */
/*                                                                               */
/*    You should have received a copy of the GNU General Public                  */
/*    License along with this program; if not, write to the Free Software        */
/*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   */
/*    02111-1307  USA                                                            */
/*                                                                               */
/*    As a special exception, you have permission to link this program           */
/*    with the OCaml compiler and distribute executables, as long as you         */
/*    follow the requirements of the GNU GPL in regard to all of the             */
/*    software in the executable aside from the OCaml compiler.                  */
/*                                                                               */
/*    Contact: Maxence.Guesdon@inria.fr                                          */
/*                                                                               */
/*********************************************************************************/

%{

%}

%token EOF
%token COLON
%token EQUAL
%token PLUSEQUAL
%token MINUSEQUAL
%token LBRACE RBRACE
%token <string> String
%token <string> Id

%type <Odb_project_types.phrase list> phrases
%start phrases
%%
phrases:
| phrase phrases { $1 :: $2 }
| phrase { [$1] }
;

phrase:
| vardef {
  let (a,b,c) = $1 in
  Odb_project_types.Vardef (a, b, c)
 }
| rule {
  let (a, l) = $1 in
  Odb_project_types.Rule (a, l)
  }
;

ids:
| id ids { $1 :: $2 }
| id { [$1] }
;

vardef:
| id opn String { ($1, $2, $3) }
;

vardefs:
| vardef vardefs { $1 :: $2 }
| vardef { [$1] }
;

rule:
ids LBRACE vardefs RBRACE { ($1, $3) }
;

id: Id { $1 };

opn:
| EQUAL { Odb_project_types.Set }
| PLUSEQUAL { Odb_project_types.Plus }
| MINUSEQUAL { Odb_project_types.Minus }
;