# This file must be in ~/.config/nixpkgs/overlays/
# Ref: https://nixos.org/manual/nixpkgs/stable/#chap-overlays

self: super:

{
  delta-bin = let
    version = "0.4.3"; # out on 4 sept 2020
    extractedRelease = fetchTarball {
      url =
        "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "0an33yncn34xb47cr3spmq38fkghw719k8airjaac3nksigxkkd4";
    };
  in super.runCommand "delta-bin-${version}" { } ''
    mkdir -p $out/bin
    ln -s ${extractedRelease}/delta $out/bin/
  '';
}
