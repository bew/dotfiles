let

  # pin it for reproducibility!
  #nixpkgs = ;

  pkgs = import <nixpkgs> {};

in

  pkgs.rustPlatform.buildRustPackage rec {
    pname = "wezterm";
    version = "20201101-103216-403d002d";
    src = pkgs.fetchFromGitHub {
      owner = "wez";
      repo = pname;
      rev = version;
      sha256 = "09j49kfl03lqj3010i9fg6fchay4rqps24p8d980pqhbrzsmd1wh";
    };
    buildInputs = import ./deps.nix { inherit pkgs; };
  
    checkPhase = ""; # keep disabled??
    cargoSha256 = "sha256:0cypjpqkraj7crfpi5is58c348ywn9ill8pnmmhl78niqipvw4mk";
  
    meta = with pkgs.stdenv.lib; {
      description = "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
      homepage = "https://wezfurlong.org/wezterm/";
      license = licenses.mit;
      # maintainers = [ maintainers.tailhook ];
      # platforms = platforms.all;
    };
  }
