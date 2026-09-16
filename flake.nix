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
    jefetch = {
      url = "github:Matko802/jefetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkmanager = {
      url = "github:Matko802/sharkmanager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    artixy = {
      url = "github:Matko802/artixy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mocktail = {
      url = "git+https://github.com/komaruworld/mocktail?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shark-scrp = {
      url = "github:Matko802/shark-scrp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkshell = {
      url = "path:/mnt/ssd/My-Files/Projects/sharkshell";
      flake = false;
    };
    tuimessager = {
      url = "github:Matko802/tuimessager";
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
      jefetch,
      sharkmanager,
      artixy,
      sharkshell,
      tuimessager,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      jefetchOverlay = jefetch.overlays.default;
      sharkmanagerOverlay = sharkmanager.overlays.default;
      artixyOverlay = artixy.overlays.default;
      tuimessagerOverlay = tuimessager.overlays.default;

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
            inputs.niri.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            jefetchOverlay
            sharkmanagerOverlay
            artixyOverlay
            tuimessagerOverlay
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
      packages.x86_64-linux.sharkshell = (nixpkgs.legacyPackages.x86_64-linux.callPackage "${sharkshell}/packaging.nix" { }).sharkshell;
      packages.x86_64-linux.mocktail = inputs.mocktail.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
      packages.x86_64-linux.sharkmanager = inputs.sharkmanager.packages.x86_64-linux.default;
      packages.x86_64-linux.artixy = inputs.artixy.packages.x86_64-linux.default;
      packages.x86_64-linux.tuimessager = inputs.tuimessager.packages.x86_64-linux.default;
      packages.x86_64-linux.tuimessager-server = inputs.tuimessager.packages.x86_64-linux.tuimessager-server;
    };
}
