(** *)

type tool =
  { tool_name : string ;
    tool_execute : Unix.file_descr -> Odb_comm.command_option list -> string -> Odb_comm.response option;
  }

let tools = ref [];;

module Tool_map = Map.Make (struct type t = string let compare = compare end);;
module Socket_map = Map.Make (struct type t = Unix.file_descr let compare = compare end);;
let socket_by_tool = ref Tool_map.empty;;
let tool_by_socket = ref Socket_map.empty ;;

let remove_tool name =
  tools := List.filter (fun t -> t.tool_name <> name) !tools;
  match
    try
      let s = Tool_map.find name !socket_by_tool in
      socket_by_tool := Tool_map.remove name !socket_by_tool;
      Some s
    with
      Not_found -> None
  with
    None -> ()
  | Some s ->
      tool_by_socket := Socket_map.remove s !tool_by_socket;
      try Unix.close s with _ -> ()
;;

let add_tool_socket tool socket =
  remove_tool tool.tool_name ;
  socket_by_tool := Tool_map.add tool.tool_name socket !socket_by_tool;
  tool_by_socket := Socket_map.add socket tool.tool_name !tool_by_socket
;;

exception Unknown_tool of string;;

let get_tool name =
  try List.find (fun t -> t.tool_name = name) !tools
  with Not_found -> raise (Unknown_tool name)
;;

let register_tool ?socket tool =
  (
   match socket with
     None -> ()
   | Some s -> add_tool_socket tool s
  );
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

(* Hack to force the inclusion of terminfo.o (found in libasmrun.lib).
  Thanks to Alain Frisch.*)
external setup : unit -> unit = "caml_terminfo_setup"
let () = if false then setup ()
(* /Hack *)

let () = Dynlink.allow_unsafe_modules true;;
let load_tool filename =
  try Dynlink.loadfile filename
  with Dynlink.Error e ->
      prerr_endline (Dynlink.error_message e)
;;

exception Unknown_command of string;;

let mk_tool name commands =
  let execute socket options phrase =
    let command = Odb_commands.command_of_string phrase in
    try
      let f =
        try List.assoc command.(0) commands
        with Not_found -> raise (Unknown_command command.(0))
      in
      f socket options (Array.sub command 1 ((Array.length command) - 1))
    with Unknown_command com ->
        Some
        (Odb_comm.mk_response ~tool: name ~code: 1
         (Printf.sprintf "Unknown command \"%s\" for tool \"%s\"" com name))
  in
  { tool_name = name ;
    tool_execute = execute ;
  }
;;

let register_remote_tool name tool_socket =
  let inch = Unix.in_channel_of_descr tool_socket in
  let ouch = Unix.out_channel_of_descr tool_socket in
  let execute client_socket options phrase =
    Odb_comm.output_command ouch
    (Odb_comm.mk_command ~tool: name ~options phrase);
    let response = Odb_comm.input_response inch in
    Odb_comm.output_response (Unix.out_channel_of_descr client_socket) response;
    None
  in
  let tool = { tool_name = name ; tool_execute = execute } in
  register_tool ~socket: tool_socket tool;

;;
