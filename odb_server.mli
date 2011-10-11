(** Server side. *)

(** The name of the server tool (i.e. "server"). If the name
  of the server tool change, using this value will make
  the change transparent. *)
val server_tool : string

(** The server documentation. *)
val server_doc : Odb_doc.tool_doc

(** {2 Handling command line options}

These values can be useful when creating a command-line server.
The {!start_server} function will use {!port} to known which
port to listen to.
 *)

val port : int ref

(** Command line options which can be append to other command
  line options.
  By now, only one option, [-p], allows to set {!port}.*)
val options : (string * Arg.spec * string) list

(** Basic usage message prefix. *)
val usage : string

(** {2 Starting the server} *)

(** [start_server ()] will make the current program a server,
  by listening on port number {!port}.
  @param with_server_tool must be set to [false] when launching
  a secondary server, since the "server" tool is already
  registered in the main server. Default value is [true]. *)
val start_server : ?with_server_tool:bool -> unit -> unit
