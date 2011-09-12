let file = Sys.argv.(1);;

let phrases = Odb_project.parse_project_file file ;;
let env = Odb_project.build_env phrases;;
let s = Odb_project.print_env env;;
prerr_endline s;;
