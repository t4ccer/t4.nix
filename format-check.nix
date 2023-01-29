{
  self,
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;
  inherit
    (lib)
    types
    mkEnableOption
    mkOption
    ;
in {
  options = {
    perSystem =
      mkPerSystemOption
      ({
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        formatCheckSubmodule = types.submodule {
          options = {
            enable = mkEnableOption "format check";

            src = mkOption {
              type = types.path;
              default = self.outPath;
              description = "Path to the source to check.";
            };

            attrName = mkOption {
              type = types.str;
              default = "formatCheck";
              description = ''
                The name of the attribute to be added to the 'checks' output set.
              '';
            };

            command = mkOption {
              type = types.str;
              default = "make format";
              description = ''
                Command to run to in-place code format
              '';
            };

            nativeBuildInputs = mkOption {
              type = types.listOf types.package;
              default = self'.devShells.default.nativeBuildInputs;
              description = ''
                Packages to add to the PATH of the format check command
              '';
            };
          };
        };
      in {
        options.formatCheck = lib.mkOption {
          type = formatCheckSubmodule;
          description = ''
            Format check configuration. Use this module only if for some reason
            you cannot use `pre-commit-hooks.nix`.
          '';
        };
        config = {
          checks = {
            ${config.formatCheck.attrName} = pkgs.stdenvNoCC.mkDerivation {
              inherit (config.formatCheck) src;
              name = "format-check";
              nativeBuildInputs =
                config.formatCheck.nativeBuildInputs
                ++ [
                  pkgs.git
                ];
              buildPhase = ''
                export GIT_AUTHOR_NAME="nix"
                export GIT_COMMITTER_NAME="nix"
                export EMAIL="nix@nix.nix"
                git init
                git add .
                git commit -m "initial commit"
                ${config.formatCheck.command}
                if [[ $(git status --porcelain) ]]; then
                  git status
                  echo "Code is not formatted"
                  echo "Run '${config.formatCheck.command}' to fix"
                  exit 1
                fi
              '';
              installPhase = ''
                touch $out
              '';
            };
          };
        };
      });
  };
}
