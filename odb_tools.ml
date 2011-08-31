(** *)

type tool =
  { tool_name : string ;
    tool_execute : Comm.command_option list -> string -> Comm.response ;
  }

let tools = ref [];;

exception Unknown_tool of string;;

let get_tool name =
  try List.find (fun t -> t.tool_name = name) !tools
  with Not_found -> raise (Unknown_tool name)
;;

let register_tool tool =
  let rec iter acc = function
    [] -> tool :: acc
  | t :: q ->
      if t.tool_name = tool.tool_name then
        iter acc q
      else
        iter (t::acc) q
  in
  tools := iter [] !tools
;;

let load_tool filename =
  try Dynlink.loadfile filename
  with Dynlink.Error e ->
      prerr_endline (Dynlink.error_message e)
;;

exception Unknown_command of string;;

let mk_tool name commands =
  let execute options phrase =
    let command = Commands.command_of_string phrase in
    let f =
      try List.assoc command.(0) commands
      with Not_found -> raise (Unknown_command command.(0))
    in
    f (Array.sub command 1 ((Array.length command) - 1))
  in
  { tool_name = name ;
    tool_execute = execute ;
  }
;;
 