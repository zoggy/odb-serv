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