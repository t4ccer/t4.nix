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
        stdenvMatrixSubmodule = types.submodule ({name, ...}: {
          options = {
            stdenvs = mkOption {
              type = types.listOf types.str;
              example = ["stdenv" "clangStdenv"];
              description = ''
                List of stdenvs to use for this build.
              '';
            };

            mkDerivationAttrs = mkOption {
              type = types.attrs;
              example = {
                buildInputs = [pkgs.cmake];
              };
              description = ''
                Attributes to pass to mkDerivation.
              '';
            };
          };
        });
      in {
        options.stdenvMatrix = lib.mkOption {
          type = types.attrsOf stdenvMatrixSubmodule;
          description = ''
            A submodule for each stdenv matrix.
          '';
        };
        config = {
          packages = let
            mkSingle = name: args: stdenv: {
              name = "${name}-${stdenv}";
              value = pkgs.${stdenv}.mkDerivation args;
            };

            mkEntry = name: {
              stdenvs,
              mkDerivationAttrs,
              ...
            }:
              map (mkSingle name mkDerivationAttrs) stdenvs;
          in
            builtins.listToAttrs
            (builtins.concatLists
              (lib.attrsets.mapAttrsToList mkEntry config.stdenvMatrix));
        };
      });
  };
}
