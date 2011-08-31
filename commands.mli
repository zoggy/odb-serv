(* $Id: cam_commands.mli 758 2011-01-13 07:53:27Z zoggy $ *)

(** Commands parsing and printing *)

type command = string array

val command_of_string : string -> string array
val string_of_command : string array -> string


