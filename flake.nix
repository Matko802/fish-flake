{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qtengine = {
      url = "github:kossLAN/qtengine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkvis = {
      url = "github:Matko802/sharkvis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkvis-gtk = {
      url = "git+file:///mnt/ssd/My-Files/Projects/sharkvis-gtk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mocktail = {
      url = "git+https://github.com/komaruworld/mocktail?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      helium-flake,
      sharkvis,
      sharkvis-gtk,
      mango,
      mocktail,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkvisGtkOverlay = sharkvis-gtk.overlays.default;

      sharedModules = [

        ({ pkgs, ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
            auto-optimise-store = true;
            keep-outputs = true;
            keep-derivations = true;
          };

          nixpkgs.overlays = [
            helium-flake.overlays.default
            sharkvisOverlay
            sharkvisGtkOverlay
            mango.overlays.default
          ];

          environment.systemPackages = [
            pkgs.helium
            inputs.mocktail.packages.x86_64-linux.default
          ];
        })
      ];

      mkHost = machineModule: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = sharedModules ++ [ machineModule ];
      };
    in
    {
      nixosConfigurations.machine1 = mkHost ./Machine/machine-config.nix;
      nixosConfigurations.machine2 = mkHost ./Machine2/machine-config.nix;
      packages.x86_64-linux.sharkvis = inputs.sharkvis.packages.x86_64-linux.default;
      packages.x86_64-linux.sharkvis-gtk = inputs.sharkvis-gtk.packages.x86_64-linux.default;
      packages.x86_64-linux.mocktail = inputs.mocktail.packages.x86_64-linux.default;
    };
}
