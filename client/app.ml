open! Core
open Bonsai_web

let component graph =
  let counter_and_set_counter =
    Bonsai.state Shared.Message.initial_counter graph
  in
  let name_and_set_name = Bonsai.state "" graph in
  let counter, set_counter = counter_and_set_counter in
  let name, set_name = name_and_set_name in
  let open Bonsai.Let_syntax in
  let%arr counter = counter
  and set_counter = set_counter
  and name = name
  and set_name = set_name in
  let open Vdom in
  Node.div
    ~attrs:[]
    [ Node.h1 ~attrs:[] [ Node.text Shared.Message.greeting ]
    ; Node.p ~attrs:[] [ Node.text "This is a minimal Bonsai + js_of_ocaml client." ]
    ; Node.div
        ~attrs:[]
        [ Node.label
            ~attrs:[]
            [ Node.text "Your name: "
            ; Node.input
                ~attrs:
                  [ Attr.type_ "text"
                  ; Attr.value name
                  ; Attr.on_input (fun _ value -> set_name value)
                  ]
                ()
            ]
        ]
    ; Node.p
        ~attrs:[]
        [ Node.text
            (if String.is_empty name then "Say hello by typing above!"
             else [%string "Hello, %{name}!" ])
        ]
    ; Node.div
        ~attrs:[]
        [ Node.button
            ~attrs:[ Attr.on_click (fun _ -> set_counter (counter + 1)) ]
            [ Node.text "Increment" ]
        ; Node.button
            ~attrs:
              [ Attr.on_click (fun _ -> set_counter Shared.Message.initial_counter) ]
            [ Node.text "Reset" ]
        ]
    ; Node.p ~attrs:[] [ Node.text [%string "Current clicks: %{counter#Int}"] ]
    ]
;;

let () =
  Start.start component ~bind_to_element_with_id:"app"
