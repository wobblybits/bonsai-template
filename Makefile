.PHONY: build serve watch clean fmt test

build:
	dune build client/app.bc.js

serve:
	dune exec server/server.exe

watch:
	watchexec -e ml -- dune build client/app.bc.js

clean:
	dune clean

fmt:
	dune fmt

test:
	dune runtest

