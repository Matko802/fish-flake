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
    xwayland-satellite = {
      url = "github:Supreeeme/xwayland-satellite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shark-scrp = {
      url = "github:Matko802/shark-scrp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lmms-appimage = {
      url = "github:Matko802/lmms-appimage-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkshell = {
      url = "path:/mnt/ssd/My-Files/Projects/sharkshell";
      flake = false;
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
      lmms-appimage,
      jefetch,
      sharkmanager,
      artixy,
      sharkshell,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      lmmsAppimageOverlay = lmms-appimage.overlays.default;
      jefetchOverlay = jefetch.overlays.default;
      sharkmanagerOverlay = sharkmanager.overlays.default;
      artixyOverlay = artixy.overlays.default;

      sharedModules = [
        ({ ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
            http-connections = 50;
            auto-optimise-store = true;
            keep-outputs = true;
            keep-derivations = true;
          };

          nixpkgs.overlays = [
            helium-flake.overlays.default
            inputs.xwayland-satellite.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            lmmsAppimageOverlay
            jefetchOverlay
            sharkmanagerOverlay
            artixyOverlay
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
      packages.x86_64-linux.lmms-appimage = inputs.lmms-appimage.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
      packages.x86_64-linux.sharkmanager = inputs.sharkmanager.packages.x86_64-linux.default;
      packages.x86_64-linux.artixy = inputs.artixy.packages.x86_64-linux.default;
    };
}
