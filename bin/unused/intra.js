#!/usr/bin/env node

var child_process = require("child_process");
var fs = require('fs');

var log = console.log;

function getUserHome() {
	return process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;
}

// get_autologin_HASH ? then return only the hash ?
function get_autologin_link () {
	var hash = null;
	try {
		hash = fs.readFileSync(getUserHome() + "/hash-autologin");
	} catch (error) {
		if (error.code !== 'ENOENT')
			throw error;
	}
	//TODO check if it's a valid hash
	if (!hash)
		exit_script(1, "Cannot get your autologin hash\nMake sure you saved your hash in file '~/hash-autologin'");
	return ("https://intra.epitech.eu/auth-" + hash);
}

var url_autologin	= get_autologin_link();
var url_intra_data	= 'https://intra.epitech.eu' + '?format=json';

var login_cmd		= 'curl -sb cookies.txt -c cookies.txt ' + url_autologin;
var intra_data_cmd	= 'curl -sb cookies.txt -c cookies.txt ' + url_intra_data;


log("Login in progress");
child_process.exec(login_cmd, function (error, stdout, stderr) {
	if (error)
		exit_script(1, "While trying to login...");
	log("Getting data...");
	child_process.exec(intra_data_cmd, function (error, stdout, stderr) {
		if (error)
			exit_script(1, "While retrieving intra's data...");
		stdout = stdout.substring(stdout.indexOf("\n") + 1);
		var intra_json = JSON.parse(stdout);
		log("Hello " + intra_json.infos.login + " !!");
		log("Current log time: " + intra_json.current.active_log);
	});
});

function die (error_msg, exit_code) {
	var msg = "";
	if (exit_code)
		msg += "[" + exit_code + "] ";
	if (error_msg)
		msg += "Error: " + error_msg;
	else
		msg += "Die.";
	log(msg);
	if (exit_code)
		process.exit(exit_code);
	else
		process.exit(1);
}

function exit_script (exit_code, msg) {
	child_process.exec("rm -f cookies.txt");
	if (exit_code != 0) // => Error
		die(msg, exit_code);
	process.exit(0);
}
