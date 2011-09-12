(** *)

type opn = Set | Plus | Minus;;
type vardef = string * opn * string;;
type rule = string list * vardef list;;

type phrase = Vardef of vardef | Rule of rule;;

module SMap = Map.Make
  (struct type t = string let compare = Pervasives.compare end);;

type env = {
  env_vars : string SMap.t ;
  env_targets : (string SMap.t) SMap.t ;
};;


let empty_env =
  { env_vars = SMap.empty ;
    env_targets = SMap.empty ;
  }
;;

(** [add_vars env1 vars] add [vars] to [env1.env_vars], enventually
  masking existing associations. *)
let add_vars env1 vars =
  let v =
    SMap.fold SMap.add
    vars
    env1.env_vars
  in
  { env1 with env_vars = v }
;;
