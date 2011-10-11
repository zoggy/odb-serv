(** Client side (i.e. secondary server).

 A secondary server is also a client for the main server.
 *)

(** [register_to_server tool_name local_port remote_host remote_port]
  register the givne tool of the current program to the main server
  specified by [remote_host] and [remote_port]. By now, remote_host should
  be ["localhost"] as secondary servers and main server can not be
  on different hosts. The [local_port] is the port of the current program,
  which the main server should connect back to when needing to call the
  tool [tool_name].
  The function returns a connection to the server and the list of
  tools that the server knows, so that the current program can
  register these tools as remote tools (after filtering its own tools).
*)
val register_to_server :
  string -> int -> string -> int -> Unix.file_descr * string list

(** {2 Low level functions} *)

val open_connection : Unix.inet_addr -> int -> Unix.file_descr
val inet_addr_of_name : string -> Unix.inet_addr
val connect : string -> int -> Unix.file_descr
