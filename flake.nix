{
  description = "NixOS base for jetson testing";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
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
        ];
      };
    };
}
