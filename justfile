_default:
  @{{just_executable()}} --list

# Build the current home config WITHOUT switching to it
build:
  #!/usr/bin/env bash
  cd "{{justfile_directory()}}"
  nix build .#homeConfig.activationPackage

# Build the current home config AND switch to it
switch: build
  #!/usr/bin/env bash
  cd "{{justfile_directory()}}"
  ./result/activate
