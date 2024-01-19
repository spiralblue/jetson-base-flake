{
  description = "NixOS base for jetson testing";

  inputs = {
    base.url = "github:spiralblue/jetson-base-flake/master";
  };

  outputs = { self, base, ... }@inputs:
    {
      nixosConfigurations.jetson-dev = base.config;
    };
}
