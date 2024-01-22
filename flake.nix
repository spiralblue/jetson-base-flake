{
  description = "NixOS base for jetson testing";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05?rev=70bdadeb94ffc8806c0570eb5c2695ad29f0e421";
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
