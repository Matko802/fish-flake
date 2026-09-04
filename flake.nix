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
    sharkfetch = {
      url = "github:Matko802/sharkfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mocktail = {
      url = "git+https://github.com/komaruworld/mocktail?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shark-scrp = {
      url = "github:Matko802/shark-scrp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      helium-flake,
      sharkvis,
      mocktail,
      shark-scrp,
      sharkfetch,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      sharkfetchOverlay = sharkfetch.overlays.default;

      sharedModules = [

        ({ ... }: {
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
            sharkScrpOverlay
            sharkfetchOverlay
          ];

          environment.systemPackages = [
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
      packages.x86_64-linux.mocktail = inputs.mocktail.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.sharkfetch = inputs.sharkfetch.packages.x86_64-linux.default;
      packages.x86_64-linux.zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
    };
}
