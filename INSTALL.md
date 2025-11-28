# Installation Guide

This template ships with a helper script so you can bootstrap a working
Dream + Bonsai environment quickly. Running `scripts/setup.sh <project_name>`
will (by default) rename the template **and** create an opam switch with all
dependencies installed. The notes below describe what the script does and how to
perform the steps manually if you pass `--no-switch`.

## Prerequisites

- [opam](https://opam.ocaml.org/doc/Install.html) ≥ 2.1.0
- OCaml compiler ≥ 5.2.0 (opam will install it for you if it is missing)
- `perl` (required by `scripts/setup.sh`)
- `make`
- [`watchexec`](https://github.com/watchexec/watchexec) (optional; only needed for `make watch`)

## What `scripts/setup.sh` does

Given a project name (e.g. `my_bonsai_switch`), the script will:

1. Create a switch: `opam switch create my_bonsai_switch 5.2.0`.
2. Apply the bundled `ocamlformat` fix:
   ```sh
   opam pin add --kind=patch ocamlformat-lib patches/ocamlformat-0.28.1-base_018.patch
   opam pin add --kind=patch ocamlformat patches/ocamlformat-0.28.1-base_018.patch
   ```
3. Install dependencies declared in `<project>.opam`:
   ```sh
   opam install my_bonsai_switch.opam --deps-only
   ```
4. Remind you to load the environment:
   ```sh
   eval "$(opam env --switch my_bonsai_switch)"
   ```

After these steps you can run `make build` / `make serve` straight away.

## Alternative: create a switch manually

If you skipped the automatic setup (`--no-switch`) or want to reproduce the
environment manually, run the equivalent commands yourself:

```sh
opam switch create my_bonsai_switch 5.2.0
eval "$(opam env --switch my_bonsai_switch)"

# Make sure the Jane Street repository is available
opam repo add janestreet https://github.com/janestreet/opam-repository.git -y

# Apply the ocamlformat patch shipped with the template
opam pin add --kind=patch ocamlformat-lib patches/ocamlformat-0.28.1-base_018.patch -y
opam pin add --kind=patch ocamlformat patches/ocamlformat-0.28.1-base_018.patch -y

# Install dependencies from the (renamed) opam file
opam install my_bonsai_switch.opam --deps-only -y
```

Finally, load the environment for every new shell:

```sh
eval "$(opam env --switch my_bonsai_switch)"
```

## Keeping the switch up to date

- Run `opam update` followed by `opam upgrade` inside the switch to pick up new releases.
- If the ocamlformat packages change, reapply the patch with:
  ```sh
  opam pin add --kind=patch ocamlformat-lib patches/ocamlformat-0.28.1-base_018.patch -y
  opam pin add --kind=patch ocamlformat patches/ocamlformat-0.28.1-base_018.patch -y
  ```
- After editing dependencies in `<project>.opam`, share them with teammates by committing the file.
