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
            mkSingle = stdenv: args: let
              name = args.name or "${args.pname or args.name}";
            in {
              name = "${stdenv}-${name}";
              value = pkgs.${stdenv}.mkDerivation args;
            };

            mkEntry = {
              stdenvs,
              mkDerivationAttrs,
              ...
            }:
              map (stdenv: mkSingle stdenv mkDerivationAttrs) stdenvs;
          in
            builtins.listToAttrs
            (builtins.concatLists
              (lib.attrsets.mapAttrsToList (_: mkEntry) config.stdenvMatrix));
        };
      });
  };
}
