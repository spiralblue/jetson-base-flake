{
  description = "NixOS base for jetson testing";

  inputs = {
    nixpkgs.url = "github:spiralblue/jetson-base-flake/master";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    with inputs;
    let
      lib = nixpkgs.lib;
      system = "aarch64-linux";
    in
    {
      nixosConfigurations = {
        jetson-dev = lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./configuration.nix
          ];
        };
      };
      config = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configuration.nix
        ];
      };
    };
}
