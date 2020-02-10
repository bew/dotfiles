# load ssh keys in the current shell
#-------------------------------------------------------------
function loadsshkeys
{
  eval `ssh-agent`
  ssh-add `find ~/.ssh -name "id_*" -a \! -name "*.pub"`
}

# Check if the ssh agent should be running but is dead
#
# For example: after a 'stupid' `pkill ssh`, the env var SSH_AGENT_PID will still
# exist, the target pid does not exist anymore thanks to pkill.
if [[ -n "$SSH_AGENT_PID" ]] && ! kill -0 "$SSH_AGENT_PID" >& /dev/null; then
  echo "The ssh agent should be running but is dead, reloading ssh keys!"
  loadsshkeys >& /dev/null
fi
