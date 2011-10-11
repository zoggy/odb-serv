(** Documenting tools. *)

(** Documentation of a command. *)
type command_doc = {
  com_name : string; (** Name of the command, e.g.: [get] *)
  com_synopsis : string; (** Synopsis, e.g.: [get <file> <var>] *)
  com_doc : string; (** Documentation (valid XHTML); keep it simple ! *)
}

(** Documentation of a tool. *)
type tool_doc =
  { tool_doc : string;  (** Introduction about the tool. *)
    tool_coms : command_doc list;  (** Documentation of commands. *)
  }

(** {2 Generating XHTML from documentation specification} *)

val escape_html : string -> string
val html_of_command_doc : Buffer.t -> command_doc -> unit
val html_of_tool_doc : tool_doc -> string
val css_style : string
val html_header : string
val html_page : (string * string) list -> string
