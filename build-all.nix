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
        buildAllSubmodule = types.submodule {
          options = {
            enable = mkEnableOption "format check";

            attrName = mkOption {
              type = types.str;
              default = "all";
              description = "Attribute name to use for the 'all' target";
            };
          };
        };
      in {
        options.buildAll = lib.mkOption {
          type = buildAllSubmodule;
          description = ''
            Combined option to build all packages.
          '';
        };
        config = {
          packages = {
            ${config.buildAll.attrName} =
              pkgs.runCommand "all" {
                FOO =
                  builtins.attrValues
                  (pkgs.lib.attrsets.filterAttrs (name: _: name != config.buildAll.attrName) self'.packages)
                  ++ builtins.attrValues self'.checks
                  ++ builtins.attrValues self'.devShells;
              } ''
                touch $out
              '';
          };
        };
      });
  };
}
