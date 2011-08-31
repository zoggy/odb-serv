(** *)

type command_option = string * string;;

type command =
  { com_tool : string ; (** name of plugin, or "server", or "project", ... *)
    com_options : command_option list ; (** eventually options for the tool *)
    com_phrase : string ; (** the command to be executed by the tool *)
  }

(** FIXME: parse tool options *)
let input_command inch =
  try
    let line1 = input_line inch in
    let line2 = Misc.strip_string (input_line inch) in
    { com_tool = line1 ; com_options = [] ; com_phrase = line2 }
  with
    End_of_file ->
      failwith "Incomplete command"
;;

(** FIXME: handle command options *)
let output_command ouch com =
  try
    Printf.fprintf ouch
    "%s\n%s"
    com.com_tool
    com.com_phrase;
    Pervasives.flush ouch
  with
    _ -> failwith "Could not send command"
;;

type response =
  {
    resp_tool : string ;
    resp_code : int ;
    resp_contents : string ;
  }

(* From Didier Remy's course *)
let rec really_read desc buffer start length =
  if length <= 0 then ()
  else
    match Unix.read desc buffer start length with
      0 -> raise End_of_file
    | r -> really_read desc buffer (start+r) (length-r);;
(* /Didier Remy *)

let input_response inch =
  try
    let line = input_line inch in
    let (tool, code, size) =
      Scanf.sscanf line "%s %d %d"
      (fun tool code size -> (tool, code, size))
    in
    let s = String.create size in
    really_read (Unix.descr_of_in_channel inch) s 0 size;
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
    Pervasives.flush ouch
  with
    _ -> failwith "Could not send response"
;;
