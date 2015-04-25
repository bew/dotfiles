/ ========= /
/   IDEE    /
/ ========= /

/ >> Une API de génération de PS1 << /

var generator = require("ps1_generator");

var ps1 = generator.init();

ps1.setStyle({
	bold: true,
	italic: true,
	color: "red"
});
ps1.addText("Hello");

ps1.setStyle({
	bold: false,
	color: "green"
});
ps1.addText(" blabla $> ");
console.log(ps1.generate());

/ Autre syntaxe possible /

var generator = require("ps1_generator")(process.argv);

var ps1 = generator.init();

ps1.add({
	bold: true,
	italic: true,
	color: "red",
	text: "hello"
});

ps1.add({
	bold: false,
	color: "green",
	text: " blabla $> "
});

console.log(ps1.generate());


/ Acces aux infos d'un PS1 /

var infos = require("ps1_infos")(process.argv);

infos.isRoot();
// true     if \$ == "#"
// false    if \$ == "$"

infos.root;
// output \$

infos.user;
// output \u

infos.host;
// output \h

infos.short_path;
// output \W

infos.path;
// output \w

infos.count;
// output \#

//etc....
