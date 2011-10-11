(** Communications. *)

(** {2 Commands} *)

(** A command option is of the form [(key, value]). *)
type command_option = string * string

(** A command refers to a tool name, optional command options, and the
  phrase to execute. *)
type command = {
  com_tool : string;
  com_options : command_option list;
  com_phrase : string;
}

(** Convenient function to create a {!command} structure. *)
val mk_command :
  tool:string -> ?options:command_option list -> string -> command

(** This exception is raised when an error occurs when sending or
     receiving data. Syntax errors in command or response raise
     a [Failure] exception.*)
exception Error of string

(** Read a command from channel. *)
val input_command : in_channel -> command

(** Write a command to a channel. *)
val output_command : out_channel -> command -> unit

(** {2 Responses} *)

(** A response refers to a tool name in field [resp_tool].
  The [resp_contents] field contains the error message if
  the [resp_code <> 0] or else the contents of the response. *)
type response = {
  resp_tool : string;
  resp_code : int;
  resp_contents : string;
}

(** Convenient function to create a {!response} structure.
  Default code is [0]. *)
val mk_response : tool:string -> ?code:int -> string -> response

(** Read a response from a channel. *)
val input_response : in_channel -> response

(** Write a response to a channel. *)
val output_response : out_channel -> response -> unit

(** [check_response r] raises [Failure r.resp_contents] if
  [r.resp_code <> 0], else return [r.resp_contents].*)
val check_response : response -> string
