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

(** *)

type command_doc =
  { com_name : string ;
    com_synopsis : string ;
    com_doc : string ;
  }

type tool_doc =
  { tool_doc : string ;
    tool_coms : command_doc list;
  }
;;

let escape_html s =
  let b = Buffer.create 256 in
  for i = 0 to String.length s - 1 do
    let s =
      match s.[i] with
        '<' -> "&lt;"
      | '>' -> "&gt;"
      | '&' -> "&amp;"
      | c -> String.make 1 c
    in
    Buffer.add_string b s
  done;
  Buffer.contents b
;;

let div b ?s cl =
  Printf.bprintf b "<div class=\"%s\">%s" cl
    (match s with
     None -> ""
   | Some s -> Printf.sprintf "%s</div>" s)
;;
let end_div b = Buffer.add_string b "</div>";;

let html_of_command_doc b d =
  div b "odb-command";
  div b ~s: d.com_name "odb-command-name";
  let s =
    Printf.sprintf
    "<b>Synopsis:</b><span class=\"odb-synopsis\">%s</span>"
    (escape_html d.com_synopsis)
  in
  div b ~s "odb-command-synopsis";
  div b ~s: d.com_doc "odb-command-doc";
  end_div b
;;

let html_of_tool_doc d =
  let b = Buffer.create 256 in
  div b ~s: d.tool_doc "odb-tool-doc";
  List.iter (html_of_command_doc b) d.tool_coms;
  Buffer.contents b
;;

let css_style =
  [ "div.odb-command",
    [ "padding-left: 1em";
      "padding-right: 1em";
      "border-width: 0 0 0 2px ";
      "border-style: solid";
      "border-color: #CCCCCC";
    ] ;
    "div.odb-command-name", [ "font-family: courier" ];
    "div.odb-command-synopsis", [ "margin-left: 2em" ] ;
    "span.odb-synopsis", [ "font-family: courier" ; "margin-left: 1em" ] ;
    "div.odb-command-doc", [ "margin-left: 2em" ];
    "div.odb-tool", [ "margin-bottom: 2em"] ;
    "div.odb-tool-name",
    [ "font-size: 20pt" ;
    ] ;
    "div.odb-tool-doc",
    ["font-style: italic";
      "margin-left: 2em";
      "margin-bottom: 1em";
      "margin-right: 2em";
    ];
    "div.odb-page",
    ["font-family: arial,sans-serif" ;
      "margin-left: auto";"margin-right:auto";"width: 700px";
    ];
  ]

let css_style =
  String.concat "\n"
  (List.map
   (fun (cl, atts) ->
      Printf.sprintf "%s { %s }\n" cl
      (String.concat ";" atts)
   )
   css_style
  )
;;

let html_header =
"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\"><html>
<head><title>Odb-server: available tools</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\"/>
<style type=\"text/css\">"^css_style^
"</style></head><body><div class=\"odb-page\">\n"
;;

let html_page tools =
  let b = Buffer.create 256 in
  Buffer.add_string b html_header;
  let f_tool (tool_name, doc) =
    div b "odb-tool";
    div b ~s: tool_name "odb-tool-name" ;
    Buffer.add_string b doc;
    end_div b;
  in
  List.iter f_tool
  (List.sort (fun (t1,_) (t2,_) -> Pervasives.compare t1 t2) tools);
  Buffer.add_string b "</div></body></html>";
  Buffer.contents b
;;
