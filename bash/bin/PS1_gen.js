#!/usr/bin/env node

/*
	to test: set your PS1 as follow:

	PS1="\`~/bin/PS1_gen.js\`"

	enjoy !
*/

// try: PS1="\`~/bin/PS1_gen.js \W \w \u \h \# \$ \`"
if (process.argv.slice(2)[0])
	console.log(process.argv.slice(2));

console.log("PS1 par noey=====>  ");
