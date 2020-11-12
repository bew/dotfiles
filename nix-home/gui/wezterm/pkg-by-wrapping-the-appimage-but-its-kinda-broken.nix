
let
  # FIXME: how to get access to pkgs from here?!
  # Is it accessible somehow using home-manager? (Is it a good idea?)
  # How would I pass it to here?
  pkgs = import <nixpkgs> {};
  appimageTools = pkgs.appimageTools;

  # FIXME: how to 'attach' better the version field to the url / name / ..
  # Would it be a good idea to manage the appimage with niv? (using url template & version)
  version = "20201101-103216-403d002d";
in

# doc at: https://nixos.org/manual/nixpkgs/stable/#ssec-pkgs-appimageTools-wrapping
appimageTools.wrapType2 {
  name = "wezterm-${version}";
  src = pkgs.fetchurl { 
    # FIXME: how to use a specific nightly?
    # a proper way to fix that would be to host all the nightly builds I use in
    # a public CAS (content addressed storage) (with useful names like in nix?),
    # and point this derivation to a specific nightly build in that storage.
    # And I could have a script/binary that takes a file and store it in that CAS,
    # then printing the public URL to it afterward..
    url = "https://github.com/wez/wezterm/releases/download/${version}/WezTerm-${version}-Ubuntu16.04.AppImage";
    sha256 =  "0zhq164x03d275rnmik4s0fic6wx6r7ixs80yxx77i58zg0315p9";
  };
}
