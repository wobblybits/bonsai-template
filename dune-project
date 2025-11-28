(lang dune 3.10)
(name bonsai_template)
(generate_opam_files false)

(package
 (name bonsai_template)
 (synopsis "Simple Bonsai + Js_of_ocaml demo with Dream server")
 (depends
  dream
  bonsai
  core
  async_kernel
  ppx_jane
  (js_of_ocaml (>= 5.0))
  js_of_ocaml-ppx))
