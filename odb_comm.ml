(** *)

type command_option = string * string;;

type command =
  { com_tool : string ; (** name of plugin, or "server", or "project", ... *)
    com_options : command_option list ; (** eventually options for the tool *)
    com_phrase : string ; (** the command to be executed by the tool *)
  }

let mk_command ~tool ?(options=[]) phrase =
  { com_tool = tool ; com_options = options ; com_phrase = phrase }
;;

exception Error of string;;

(** FIXME: parse tool options *)
let input_command inch =
  try
    let line1 = input_line inch in
    let line2 = Odb_misc.strip_string (input_line inch) in
    { com_tool = line1 ; com_options = [] ; com_phrase = line2 }
  with
    End_of_file ->
      failwith "Incomplete command"
;;

(** FIXME: handle command options *)
let output_command ouch com =
  try
    Printf.fprintf ouch
    "%s\n%s\n"
    com.com_tool
    com.com_phrase;
    Pervasives.flush ouch
  with
    _ -> raise (Error "Could not send command")
;;

type response =
  {
    resp_tool : string ;
    resp_code : int ;
    resp_contents : string ;
  }

let mk_response ~tool ?(code=0) contents =
  { resp_tool = tool ;
    resp_code = code ;
    resp_contents = contents ;
  }
;;

(* From Didier Remy's course *)
let rec really_read inch buffer start length =
  if length <= 0 then ()
  else
    match Pervasives.input inch buffer start length with
      0 -> prerr_endline (Printf.sprintf "start=%d" start);raise End_of_file
    | r -> really_read inch buffer (start+r) (length-r);;
(* /Didier Remy *)

let input_response inch =
  try
    let line = input_line inch in
    let (tool, code, size) =
      Scanf.sscanf line "%s %d %d"
      (fun tool code size -> (tool, code, size))
    in
    prerr_endline (Printf.sprintf "response header: %s %d %d" tool code size);
    let s = String.create size in
    Pervasives.really_input inch s 0 size;
    { resp_tool = tool ;
      resp_code = code ;
      resp_contents = s ;
    }
  with
    End_of_file -> failwith "Incomplete response"
  | Scanf.Scan_failure s ->
      failwith (Printf.sprintf "Invalid response (%s)" s)
;;

let output_response ouch resp =
  try
    Printf.fprintf ouch "%s %d %d\n%s"
    resp.resp_tool resp.resp_code (String.length resp.resp_contents)
    resp.resp_contents  ;
    prerr_endline (Printf.sprintf "response sent: %s" (resp.resp_contents));
    Pervasives.flush ouch
  with
    _ -> raise (Error "Could not send response")
;;

let check_response r =
  if r.resp_code <> 0 then
    failwith r.resp_contents
  else
    r.resp_contents
;;

