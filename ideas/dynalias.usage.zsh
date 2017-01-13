
#----------------------------------------------------------------------------------
# Dynamic aliases (dynalias) -- plugin ideas
#----------------------------------------------------------------------------------
#

# Using command_not_found_handler

tmpfn fname --in <<END_FUNCTION
local prefix=$1
local star=$2

echo "git $star"
END_FUNCTION
dynalias 'g*' $fname

# example: 'gph -u origin master'
# will be transformed to:  'git ph -u origin master'

# example: 'glog'
# will be transformed to:  'git log'

