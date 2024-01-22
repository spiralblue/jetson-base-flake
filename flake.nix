{
  description = "NixOS base for jetson testing";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    with inputs;
    let
      lib = nixpkgs.lib;
      system = "aarch64-linux";
    in
    {
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
