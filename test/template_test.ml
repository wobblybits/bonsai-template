open! Core

let () =
  assert (Shared.Message.initial_counter = 0);
  print_endline Shared.Message.greeting

