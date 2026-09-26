# Declaratively fill config directories.
#
# `config.dir.<name>` declares either a whole-dir `source = path`, or
# `{ content = { relative-path -> entry }; postBuild = "..."; }`.
#
# Exposes the dirs to `config.outputs.dirs.<name>`.
#
# An entry is either: (note: `source` and `text` are mutually exclusive)
#   - a bare `path` / derivation              -> symlinked as-is (using `lib.mkLink`)
#   - `{ source = ...; replacements = [ ... ]; }` -> `source` is substituted into the dir
#   - `{ text = "..."; }`                     -> `text` is written as a real file in the dir
{ config, lib, pkgs, ... }:

let
  ty = lib.types;
  cfg = config;

  replacementType = ty.submodule {
    options = {
      from = lib.mkOption {
        description = "Literal text to replace";
        type = ty.str;
      };
      to = lib.mkOption {
        description = "Replacement text";
        type = ty.str;
      };
    };
  };

  # The type for an entry in a directory.
  # note: A bare path/derivation is auto-transformed into `{ source = ...; }`.
  entryType = ty.coercedTo (ty.either ty.path ty.package) (source: { inherit source; }) (ty.submodule {
    options = {
      source = lib.mkOption {
        description = "Source file/dir to link (or to substitute when `replacements` is set)";
        type = ty.nullOr (ty.either ty.path ty.package);
        default = null;
      };
      text = lib.mkOption {
        description = "Literal text content for the file (mutually exclusive with `source`)";
        type = ty.nullOr ty.str;
        default = null;
      };
      replacements = lib.mkOption {
        description = "Literal replacements to apply to the content (implies substitution, not symlink)";
        type = ty.listOf replacementType;
        default = [];
      };
    };
  });

  # Returns the script needed to create a given entry
  mkEntryAction = pathInDir: spec:
    let
      mkdirParents = ''mkdir -p "$out/$(dirname ${lib.escapeShellArg pathInDir})"'';
      replaceArgs = lib.concatStringsSep " \\\n  " (
        map (r: "--replace-fail ${lib.escapeShellArg r.from} ${lib.escapeShellArg r.to}")
          spec.replacements
      );
    in
    if spec.text != null then ''
      ${mkdirParents}
      # Quoted heredoc to ensure no possible `$`/backtick expansion in the 'pasted' text content.
      cat > "$out/${pathInDir}" << 'DIR_TEXT_EOF'
      ${spec.text}
      DIR_TEXT_EOF
      ${lib.optionalString (spec.replacements != []) ''
        substituteInPlace "$out/${pathInDir}" \
          ${replaceArgs}
      ''}
    ''
    else if spec.replacements == [] then
      # No replacements, link/embed (based on `cfg.lib.mkLink`) the source directly to its target
      let
        link = cfg.lib.mkLink spec.source;
        linkTarget =
          # NOTE: we bypass the mkLink redirector drv if there is one, we directly link to the pathInDir
          # (-> a few less drv!)
          if lib.isDerivation link && link ? passthru.dynpathRedirectTarget
          then link.passthru.dynpathRedirectTarget
          else link;
      in ''
        ${mkdirParents}
        ln -s ${lib.escapeShellArg "${linkTarget}"} "$out/${pathInDir}"
      ''
    else ''
      ${mkdirParents}
      substitute ${lib.escapeShellArg "${spec.source}"} "$out/${pathInDir}" \
        ${replaceArgs}
    '';

  mkDir = dirName: spec:
    if spec.source != null
    then
      let
        # Dynamic mode yields a redirect derivation; static mode yields a raw store path,
        # which we wrap so `outputs.dirs` stays a package (and keeps its string context).
        link = cfg.lib.mkLink spec.source;
      in
      if lib.isDerivation link
      then link
      else pkgs.runCommandLocal "toolkit-dir-${dirName}-${cfg.ID}" {} ''
        ln -s ${lib.escapeShellArg "${link}"} $out
      ''
    else pkgs.runCommandLocal "toolkit-dir-${dirName}-${cfg.ID}" {} (
      lib.concatStringsSep "\n" (
        (lib.mapAttrsToList mkEntryAction spec.content)
        ++ [ spec.postBuild ]
      )
    );

  # Every link's `lib.mkLink` result (whole-dir sources + symlink entries), for
  # activation-time checking via `dynpaths.checkedPaths`. Static results are plain paths
  # (not derivations) and get dropped; dynamic redirects carry `dynpathRedirectTarget`.
  # `text` entries are generated build artefacts, not live sources, so they are skipped.
  linkedPaths = lib.concatLists (
    lib.mapAttrsToList (_dirName: dirSpec:
      lib.optional (dirSpec.source != null) (cfg.lib.mkLink dirSpec.source)
      ++ lib.mapAttrsToList (_target: spec: cfg.lib.mkLink spec.source)
        (lib.filterAttrs (_: spec: spec.source != null && spec.replacements == []) dirSpec.content)
    ) cfg.dir
  );
in {
  options = {
    dir = lib.mkOption {
      description = "Config directories, as `name -> { source = path; }` or `name -> { content = { relative-path -> entry }; postBuild = \"\"; }`";
      type = ty.attrsOf (ty.submodule {
        options = {
          source = lib.mkOption {
            description = "Whole-dir source to link (if set, `content` is NOT used)";
            type = ty.nullOr (ty.either ty.path ty.package);
            default = null;
          };
          content = lib.mkOption {
            description = "Entries, as `relative-path -> path/derivation/submodule`";
            type = ty.attrsOf entryType;
            default = {};
          };
          postBuild = lib.mkOption {
            description = "Extra shell appended to the dir build script";
            type = ty.str;
            default = "";
          };
        };
      });
      default = {};
    };
    outputs.dirs = lib.mkOption {
      description = "Built config directories (one per `dir.<name>`)";
      type = ty.attrsOf ty.package;
    };
  };

  config = {
    outputs.dirs = lib.mapAttrs mkDir cfg.dir;
    dynpaths.checkedPaths = lib.filter lib.isDerivation linkedPaths;

    # Warn on use of both `source` & `text` for an entry
    assertions = lib.concatLists (
      lib.mapAttrsToList (dirName: dirSpec:
        lib.mapAttrsToList (pathInDir: entrySpec: {
          assertion = (entrySpec.source != null) != (entrySpec.text != null);
          message = ''dir.${dirName}.content."${pathInDir}": `source` and `text` are mutually exclusive!'';
        }) dirSpec.content
      ) cfg.dir
    );
  };
}
