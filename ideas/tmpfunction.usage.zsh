
#----------------------------------------------------------------------------------
# Temporary functions (tmpfn) -- plugin ideas
#----------------------------------------------------------------------------------
#

# Usage :
#
# tmpfn <fname> --in
# -> register a function that will executes instructions read from stdin
#
# tmpfn <fname> <instruction1> [<instruction2> [<...3>]]
# -> register a function that will executes <instruction1>, then <instruction2>, etc..
#
# Store the generated function name in <fname>


tmpfn fname 'echo lol'
# Save in 'fname' the function name : __tmpfunc_anon_42



tmpfn fname 'echo lol'
$fname
# will execute as: echo lol;
# prints:
#   lol

tmpfn fname 'echo arg is $1'
$fname foobar
# will transform to: __tmpfunc_anon_2 foobar;
# prints:
#   arg is foobar

tmpfn fname 'echo lol' ls 'echo lel'
$fname
# will execute as: echo lol; ls; echo lel;
# prints something like:
#   lol
#   somefile1 somefile2
#   lel

# same as:
tmpfn fname \
	'echo lol' \
	ls \
	'echo lel'
$fname

# For multiline function, I recommand using the --in parameter (see below)

# Concrete exemple:
#-------------------------------------------------------------

# Function declaration :
tmpfn funcname --in <<FUNCTION_END
local arg
arg="$1"
if [ $arg == 42 ]; then
	echo "success"
else
	echo "failure"
fi
FUNCTION_END

# debug, prints: __tmpfunc_anon_2
# (2 is the function ID)
echo $funcname

# Function call :
$funcname 99 # prints failure
$funcname 42 # prints success

