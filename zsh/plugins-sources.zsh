
typeset -A PLUGINS_SOURCES

# Declare where each plugin is initialized from (path or `org/repo`)
# NOTE: These lines are rewritten by Nix when packaged!
PLUGINS_SOURCES[zsh-hooks]=$ZSH_MY_CONF_DIR/third-party/zsh-hooks
PLUGINS_SOURCES[zi]=$ZSH_MY_CONF_DIR/third-party/zi
PLUGINS_SOURCES[F-Sy-H]=z-shell/F-Sy-H
PLUGINS_SOURCES[autopair]=hlissner/zsh-autopair
PLUGINS_SOURCES[autoenv]=Tarrasch/zsh-autoenv
PLUGINS_SOURCES[gitstatus]=romkatv/gitstatus
PLUGINS_SOURCES[zconvey]=z-shell/zconvey
PLUGINS_SOURCES[diralias]=bew/diralias
# Check plugin folders exist if entries are paths (start with `/`)
for plugin_path in "${PLUGINS_SOURCES[@]}"; do
  if [[ "${plugin_path[1]}" == "/" ]] && ! [[ -d "$plugin_path" ]]; then
    >&2 echo ":: Plugin folder '$plugin_path' does not exist (expect some broken stuff!)"
  fi
done

unset plugin_path
