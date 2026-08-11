{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    {
      devShells = builtins.mapAttrs (system: pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            emmylua-ls
          ];

          PZ_UMBRELLA =
            let
              Umbrella = fetchTarball {
                url = "https://github.com/PZ-Umbrella/Umbrella/archive/refs/tags/42.20.0.tar.gz";
                sha256 = "sha256:0wwwr7n8z5bg9rk3rpgq9rikqwqb8xb3rxcsdhpw012xnj0nb9lm";
              };
            in
            "${Umbrella}/library";
        };
      }) nixpkgs.legacyPackages;
    };
}
