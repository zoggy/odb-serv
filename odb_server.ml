(*********************************************************************************)
(*                Odb-server                                                     *)
(*                                                                               *)
(*    Copyright (C) 2011 Institut National de Recherche en Informatique          *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License as                    *)
(*    published by the Free Software Foundation; either version 2 of the         *)
(*    License.                                                                   *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public                  *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    As a special exception, you have permission to link this program           *)
(*    with the OCaml compiler and distribute executables, as long as you         *)
(*    follow the requirements of the GNU GPL in regard to all of the             *)
(*    software in the executable aside from the OCaml compiler.                  *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*********************************************************************************)

(** *)

open Unix;;

let server_tool = "server" ;;

(* Most of this code from Didier Remy's course *)
let open_server port =
  try
    let socket = Unix.socket PF_INET SOCK_STREAM 0 in
    Unix.setsockopt socket SO_REUSEADDR true;
    Unix.bind socket (ADDR_INET (Unix.inet_addr_any, port));
    Unix.listen socket 20;
    socket
  with _ ->
    let message = Printf.sprintf "open_server %d: can't open" port in
    raise (Failure message);;

let string_of_sockaddr s = match s with
  | ADDR_UNIX s -> s
  | ADDR_INET (inet,p) -> (Unix.string_of_inet_addr inet)^":"^(string_of_int p);;


let rec establish_iterative_server f port =
  let socket_server = open_server port in
  ignore (Sys.signal Sys.sigpipe Sys.Signal_ignore);
  let rec server () =
    prerr_endline "server()";
    begin
      try
        let (socket_connection, client_addr) = Unix.accept socket_server in
(*
        Unix.setsockopt_float socket_connection SO_RCVTIMEO 10.;
        Unix.setsockopt_float socket_connection SO_SNDTIMEO 10.;
*)        Printf.eprintf "Connection from %s.\n" (string_of_sockaddr client_addr);
        Pervasives.flush Pervasives.stderr;
        ignore(Thread.create f socket_connection);
      with
      | Unix_error(_,"accept",_) ->
          raise (Failure "establish_iterative_server: accept")
      | Failure msg ->
          prerr_endline msg;
      | e ->
          prerr_endline (Printexc.to_string e);
    end;
    server ()
  in
  server ()
(* /Didier Remy's *)

let com_register_tool options args =
  let (port, resp) =
    if Array.length args <= 0 then
      (None,
       Some (Odb_comm.mk_response ~tool: server_tool ~code: 1
         "missing tool name")
      )
    else if Array.length args <= 1 then
      (None,
       Some (Odb_comm.mk_response ~tool: server_tool ~code: 2
         "missing port number")
      )
    else
      try (Some (int_of_string args.(1)), None)
      with _ ->
        (None,
         Some (Odb_comm.mk_response ~tool: server_tool ~code: 3
           "invalid port number")
        )
  in
  match port, resp with
    None, None -> assert false
  | None, Some resp -> resp
  | Some port, _ ->
     Odb_tools.register_remote_tool args.(0) port;
     let (tools, _) = Odb_tools.get_tools () in
     let tools = Odb_tools.Tool_map.fold
       (fun name _ acc -> name :: acc) tools []
     in
     let tools = String.concat " " tools in
     Odb_comm.mk_response ~tool: server_tool tools
;;

let server_doc =
  let open Odb_doc in
  { tool_doc = "Server operations" ;
    tool_coms =
    [
      { com_name = "register" ;
        com_synopsis = "register <tool-name> <port>" ;
        com_doc = "Register a new tool with given tool-name. The port is used by the server to connect back to the secondary server providing the tool.";
      } ;
      { com_name = "version" ;
        com_synopsis = "version";
        com_doc = "Return the version number of the server. This function is useful to perform a simple test."
      } ;
    ]
  }
;;


let com_server_doc _ _ =
  let f tool_name _ acc =
    if tool_name = server_tool then
      ("server", Odb_doc.html_of_tool_doc server_doc) :: acc
    else
      begin
        let r = Odb_tools.call ~tool: tool_name "doc" in
        if r.Odb_comm.resp_code = 0 then
          (tool_name, r.Odb_comm.resp_contents) :: acc
        else
          acc
      end
  in
  let tool_docs =
    Odb_tools.Tool_map.fold f (fst (Odb_tools.get_tools())) []
  in
  let html =Odb_doc.html_page tool_docs in
  Odb_comm.mk_response ~tool: "server" html
;;

let register_server_tool () =
  let tool = Odb_tools.mk_tool server_tool
    [ "version", (fun _ _ -> Odb_comm.mk_response ~tool: server_tool Odb_config.version) ;
      "register", com_register_tool ;
      "doc", com_server_doc ;
    ]
  in
  Odb_tools.register_tool tool
;;

let handle_request socket =
  let inch = Unix.in_channel_of_descr socket in
  let ouch = Unix.out_channel_of_descr socket in
  try
    let rec iter () =
      begin
        try
          let command = Odb_comm.input_command inch in
          let response =
            Odb_tools.call ~tool: command.Odb_comm.com_tool
            ~options: command.Odb_comm.com_options
            command.Odb_comm.com_phrase
          in
          Odb_comm.output_response ouch response;
        with
          Odb_tools.Unknown_tool name ->
            let response =
              { Odb_comm.resp_tool = name ;
                 resp_code = 1 ;
                resp_contents = Printf.sprintf "Unregistered tool %s" name ;
              }
            in
            Odb_comm.output_response ouch response
        | Failure msg ->
            let response = Odb_comm.mk_response
              ~tool: "?" ~code: 1 msg
            in
            Odb_comm.output_response ouch response
        | Unix.Unix_error (e, s1, s2) ->
            let msg = Printf.sprintf "%s: %s %s"
              (Unix.error_message e) s1 s2
            in
            let response = Odb_comm.mk_response
              ~tool: "?" ~code: 1 msg
            in
            Odb_comm.output_response ouch response
        | e ->
            let response = Odb_comm.mk_response
              ~tool: "?" ~code: 1 (Printexc.to_string e)
            in
            Odb_comm.output_response ouch response
        end;
        iter ()
      in
      iter ()
  with
  | Odb_comm.Error _msg ->
      Unix.close socket
  | Sys_blocked_io ->
      prerr_endline "blocked io";
      (try Unix.close socket with _ -> ());
      Thread.exit ()
  | e ->
      let msg = Printf.sprintf
        "Exception raised in thread: %s\nthe thread now exits"
       (Printexc.to_string e)
      in
      prerr_endline msg;
      Thread.exit ()
;;

let port = ref Odb_config.default_port;;

let options = [
    "--version", Arg.Unit (fun () -> print_endline Odb_config.version; exit 0),
    " print version and exits";
    "-p", Arg.Set_int port, "<port> listen on port instead of "^(string_of_int !port) ;

  ];;

let usage = Printf.sprintf "Usage: %s [options]\nwhere options are:" Sys.argv.(0);;

let start_server ?(with_server_tool=true) () =
  try
    let tools = ref [] in
    Arg.parse options (fun s -> tools := s :: !tools) usage;
    let tools = List.rev !tools in
    if with_server_tool then register_server_tool ();
    List.iter Odb_tools.load_tool tools;
    ignore(establish_iterative_server handle_request !port)
  with
    Failure s ->
      prerr_endline s;
      exit 1
;;