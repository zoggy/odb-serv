(** *)

type tool =
  { tool_name : string ;
    tool_execute : Odb_comm.command_option list -> string -> Odb_comm.response ;
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
    let command = Odb_commands.command_of_string phrase in
    try
      let f =
        try List.assoc command.(0) commands
        with Not_found -> raise (Unknown_command command.(0))
      in
      f (Array.sub command 1 ((Array.length command) - 1))
    with Unknown_command com ->
        Odb_comm.mk_response ~tool: name ~code: 1
        (Printf.sprintf "Unknown command \"%s\" for tool \"%s\"" com name)
  in
  { tool_name = name ;
    tool_execute = execute ;
  }
;;
 