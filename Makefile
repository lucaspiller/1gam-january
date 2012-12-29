.PHONY: server dev

server:
	python -m SimpleHTTPServer

dev:
	# npm -g install coffee-script
	# TODO figure out proper way to combine multiple files
	coffee --watch --bare --output lib/ --compile src/
