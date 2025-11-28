# Bonsai + Dream Template

This starter pairs a Dream HTTP server with a Bonsai + js_of_ocaml client. It is
intended as a lightweight foundation for new Bonsai projects that need a server
to serve assets and expose a small API.

## Requirements

- [opam](https://opam.ocaml.org/doc/Install.html) ≥ 2.1
- `perl` (required by `scripts/setup.sh` for in-place edits)
- `make`
- `patch` (standard Unix `patch` utility; used when installing ocamlformat)
- [`watchexec`](https://github.com/watchexec/watchexec) (optional, used by `make watch`)

## Quick start

```sh
scripts/setup.sh my_new_project
make build
make serve
```

`scripts/setup.sh` renames the template (replacing every occurrence of
`bonsai_template`) and, by default, creates an opam switch called
`my_new_project` with all required dependencies. Pass `--no-switch` if you want
to manage the switch manually. See `INSTALL.md` for full details.

If you set up the switch yourself, remember to add the Jane Street opam
repository first:

```sh
opam repo add janestreet https://github.com/janestreet/opam-repository.git
```

## Project layout

- `shared/` – values shared between server and client (e.g. greetings, defaults).
- `client/` – Bonsai view logic compiled to JavaScript via js_of_ocaml.
- `server/` – Dream router serving static assets and a `/api/greeting` endpoint.
- `static/index.html` – host page that loads the Bonsai bundle.
- `static/assets/.gitkeep` – placeholder; `dune` writes `app.bc.js` here when built.
- `scripts/` – helper scripts (`setup.sh` bootstraps and optionally provisions a switch).
- `patches/` – small patch applied to `ocamlformat` 0.28.1 for Base v0.18 compatibility.
- `Makefile` – convenience commands (`make build`, `make serve`, `make watch`, `make fmt`).

## Tooling & configuration

- `.ocamlformat` pins the formatter profile (`janestreet`, version 0.28.1).
- `bonsai_template.opam` lists the project dependencies; the setup script renames
  it to `<project>.opam` for you.
- `Makefile` wraps the most common dune invocations.
- `.gitignore` keeps build artefacts, promoted JS bundles, and IDE state out of git.
- `.github/workflows/ci.yml` runs `dune build`/`dune runtest` in CI.
- `test/` contains a minimal sanity test that exercises the shared library.

### Make targets

| Command       | Description                                  |
|---------------|----------------------------------------------|
| `make build`  | Build the Bonsai JS bundle                   |
| `make serve`  | Run the Dream server                         |
| `make watch`  | Rebuild the client on changes (needs watchexec) |
| `make fmt`    | Format the codebase with ocamlformat         |
| `make test`   | Run dune tests (`dune runtest`)              |
| `make clean`  | Clean build artefacts                        |

## Building & running

```sh
# Build the Bonsai bundle (app.bc.js promoted into static/assets/)
make build

# Run the Dream server (listens on http://localhost:8080/)
make serve
```

You can override runtime configuration with environment variables:

```sh
PORT=9090 STATIC_DIR=$PWD/static ASSETS_DIR=$PWD/static/assets make serve
```

For quick feedback while editing client code:

```sh
make watch   # requires watchexec
```

## Static assets

`dune build client/app.bc.js` produces the JavaScript bundle under
`_build/default/client/`. The dune rule promotes the bundle into
`static/assets/app.bc.js` so Dream can serve it directly. The `.gitkeep` file
keeps the directory in version control without committing generated bundles.

## Documentation & next steps

- Read `INSTALL.md` for switch creation details, especially if you used
  `--no-switch` or want to reproduce the setup manually.
- Inspect `client/app.ml` to see the Bonsai state primitives used in the sample UI.
- Extend the Dream server (`server/server.ml`) with new routes or APIs.
- Consider adding persistence, user authentication, or multi-component Bonsai apps.
- Explore the Bonsai docs: https://opensource.janestreet.com/bonsai/
  and Dream guide: https://aantron.github.io/dream/
- Build confidence with tests in `test/`; add expectation tests or integration checks as you grow the app.

Happy hacking!
