{
  description = "NixOS base for jetson testing";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    jetpack-nixos = {
      url = "github:anduril/jetpack-nixos/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, jetpack-nixos, ... }@inputs:
    with inputs;
    let
      lib = nixpkgs.lib;
      system = "aarch64-linux";
    in
    {
      nixosConfigurations.jetson-dev = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          ./jetson-dev.nix
          jetpack-nixos.nixosModules.default
        ];
      };

      nixosConfigurations.jetson-tester = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          ./jetson-tester.nix
          jetpack-nixos.nixosModules.default
        ];
      };
    };
}
