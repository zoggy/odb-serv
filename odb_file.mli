(** File utils. *)

(** Normalize a filename path, by going up in directories,
   to get a name without symbolic links. *)
val normalized_path : string -> string
