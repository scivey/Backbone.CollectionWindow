MAINSCRIPT=./bin/Backbone.CollectionWindow.js

main: compile

compile:
	coffee -c ./
	cp ./index.js $(MAINSCRIPT)

test: compile
	mocha -R spec ./spec
