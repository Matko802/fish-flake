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
    sharkmanager = {
      url = "path:/mnt/ssd/My-Files/Projects/sharkmanager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shark-scrp = {
      url = "path:/mnt/ssd/My-Files/Projects/shark-scrp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode-desktop = {
      url = "path:/mnt/ssd/My-Files/Projects/opencode-desktop-rs";
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
      sharkmanager,
      shark-scrp,
      opencode-desktop,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkvisGtkOverlay = sharkvis-gtk.overlays.default;
      sharkmanagerOverlay = sharkmanager.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      opencodeDesktopOverlay = opencode-desktop.overlays.default;

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
            (final: prev: {
              xorg = prev.xorg // {
                libX11 = final.libx11;
                libxcb = final.libxcb;
                libXau = final.libxau;
                libXdmcp = final.libxdmcp;
                libXext = final.libXext;
                libXft = final.libxft;
                libXinerama = final.libXinerama;
                libXrandr = final.libXrandr;
                libXrender = final.libXrender;
                libXfixes = final.libXfixes;
                libXi = final.libXi;
                libXcursor = final.libXcursor;
                libXcomposite = final.libXcomposite;
                libXdamage = final.libXdamage;
                libXtst = final.libXtst;
                libXScrnSaver = final.libxscrnsaver;
              };
            })
            helium-flake.overlays.default
            sharkvisOverlay
            sharkvisGtkOverlay
            mango.overlays.default
            sharkmanagerOverlay
            sharkScrpOverlay
            opencodeDesktopOverlay
          ];

          environment.systemPackages = [
            pkgs.helium
            inputs.mocktail.packages.x86_64-linux.default
            pkgs.shark-scrp
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
      packages.x86_64-linux.sharkmanager = inputs.sharkmanager.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.opencode-desktop = inputs.opencode-desktop.packages.x86_64-linux.default;
    };
}
