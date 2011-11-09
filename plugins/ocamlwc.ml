(** Toy plugin: use ocamlwc on a file. *)

let tool_name = "ocamlwc";;

let run_ocamlwc file =
  try
    let inch = Unix.open_process_in
      (Printf.sprintf "ocamlwc %s" (Filename.quote file))
    in
    let line = input_line inch in
    let (_code, comment) = Scanf.sscanf line "%[ ]%d%[ ]%d"
      (fun _ a _ b -> (a,b))
    in
    ignore(Unix.close_process_in inch);
    Odb_comm.mk_response ~tool: tool_name
    (string_of_int comment)
  with Unix.Unix_error (e,s1,s2) ->
      let msg = Printf.sprintf
        "Exec error: %s: %s %s"
        (Unix.error_message e) s1 s2
      in
      failwith msg
;;

(** Define a function which will be associated to the "comments" command.
  This function takes options and command arguments. Options are not used
  in this example. *)
let show options args =
  if Array.length args < 1 then
    Odb_comm.mk_response ~tool: tool_name
    ~code: 1 "No filename"
  else
    run_ocamlwc args.(0)
;;

(** Define the documentation of the tool. *)
let doc =
  {
    Odb_doc.tool_doc = "Use ocamlwc to get information." ;
    tool_coms =
      [
      { Odb_doc.com_name = "comments" ;
        com_synopsis = "comments [filename]" ;
        com_doc = "Return the number of comment lines in the given file." ;
      }
    ]
  }
;;

(** Create our tool, which its doc, and a list of commands,
  containing only the "comments" command, with the [show] function
  associated.*)
let tool = Odb_tools.mk_tool tool_name ~doc
  [ "comments", show ]
;;

(** Do not forget to register the tool. *)
Odb_tools.register_tool tool;;
