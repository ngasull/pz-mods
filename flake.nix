{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "steam-unwrapped"
            "steamcmd"
          ];
      };
      sync-packages = pkgs.callPackage ./sync.nix { };
    in
    {
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages =
          (with pkgs; [
            lua-language-server
            steamcmd
          ])
          ++ sync-packages;

        PZ_UMBRELLA =
          let
            Umbrella = fetchTarball {
              url = "https://github.com/PZ-Umbrella/Umbrella/archive/refs/tags/42.20.0.tar.gz";
              sha256 = "sha256:0wwwr7n8z5bg9rk3rpgq9rikqwqb8xb3rxcsdhpw012xnj0nb9lm";
            };
          in
          "${Umbrella}/library";
      };
    };
}
