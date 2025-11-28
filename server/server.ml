let static_dir =
  Sys.getenv_opt "STATIC_DIR"
  |> Option.value ~default:(Filename.concat (Sys.getcwd ()) "static")

let assets_dir =
  match Sys.getenv_opt "ASSETS_DIR" with
  | Some dir -> dir
  | None ->
      let candidate = Filename.concat static_dir "assets" in
      if Sys.file_exists (Filename.concat candidate "app.bc.js")
      then candidate
      else Filename.concat (Sys.getcwd ()) "_build/default/client"

let index_path = Filename.concat static_dir "index.html"
let bundle_path = Filename.concat assets_dir "app.bc.js"

let () =
  if not (Sys.file_exists index_path) then
    Format.eprintf
      "[server] Warning: expected to find %s. Run `dune build client/app.bc.js` first.\n"
      index_path
  else if not (Sys.file_exists bundle_path) then
    Format.eprintf
      "[server] Warning: expected to find %s. Run `dune build client/app.bc.js` to generate it.\n"
      bundle_path

let read_file path =
  let ic = open_in_bin path in
  let length = in_channel_length ic in
  let contents = really_input_string ic length in
  close_in ic;
  contents

let index_handler _ =
  if Sys.file_exists index_path
  then Dream.html (read_file index_path)
  else
    Dream.html
      ~status:`Internal_Server_Error
      "Static assets are missing. Run `dune build client/app.bc.js` to generate them."

let greeting_handler _ =
  Dream.json (Printf.sprintf "{\"greeting\":\"%s\"}" Shared.Message.greeting)

let () =
  let port =
    Sys.getenv_opt "PORT"
    |> fun opt -> Option.bind opt int_of_string_opt
    |> Option.value ~default:8080
  in
  Dream.run
    ~interface:"0.0.0.0"
    ~port
    @@ Dream.logger
    @@ Dream.router
         [ Dream.get "/" index_handler
         ; Dream.get "/assets/**" (Dream.static assets_dir)
         ; Dream.get "/api/greeting" greeting_handler
         ]
