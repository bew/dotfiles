{
  lib,
  config,
  ...
}:

{
  config = {
    # OVERWRITE how homeManager uninstalls then installs itself.
    # The previous `installPackages` step was never able to uninstall a `nix profile install`-ed home manager package (even though I didn't do stuff manually, just activating the previous one normally)
    # Ref on Matrix:
    # https://app.element.io/#/room/#hm:rycee.net/$C_F5ZaaA3ZBYje5CDdi0oSdsY_IXR2mmmjeaYNwEiOM
    home.activation.installPackages = lib.mkForce (
      lib.hm.dag.entryAfter ["writeBoundary"] (/* sh */ ''
        _i "Uninstalling existing (old) profile..."
        if [[ -e "$nixProfilePath"/manifest.json ]] ; then
            INSTALL_CMD="nix profile install"
            LIST_CMD="nix profile list"
            REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
            nix profile list \
                | { grep 'home-manager-path$' || test $? = 1; } \
                | cut -d ' ' -f 4 \
                | xargs -t $DRY_RUN_CMD nix profile remove $VERBOSE_ARG
        elif nix-env -q | grep '^home-manager-path$'; then
            INSTALL_CMD="nix-env -i"
            LIST_CMD="nix-env -q"
            REMOVE_CMD_SYNTAX='nix-env -e {package name}'
            # Remove old 
            $DRY_RUN_CMD nix-env -e home-manager-path
        fi

        _i "Installing new profile... (using '$INSTALL_CMD ...')"
        if $DRY_RUN_CMD $INSTALL_CMD ${config.home.path} ; then
          _i "All good :)"
        else
          echo
          _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
          exit 1
        fi
        unset INSTALL_CMD LIST_CMD REMOVE_CMD_SYNTAX
      '')
    );
  };
}
