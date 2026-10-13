{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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
    mocktail = {
      url = "git+https://github.com/komaruworld/mocktail?ref=main";
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
    musishark = {
      url = "github:Matko802/musishark";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ruwa = {
      url = "github:Matko802/ruwa";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pandora-launcher = {
      url = "github:Matko802/PandoraLauncher-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rootapp = {
      url = "github:Matko802/rootapp-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkshell = {
      url = "github:Matko802/sharkshell";
      flake = false;
    };
    proton-cachyos = {
      url = "github:Daaboulex/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      helium-flake,
      zen-browser,
      qtengine,
      sharkvis,
      mocktail,
      shark-scrp,
      lmms-appimage,
      musishark,
      ruwa,
      pandora-launcher,
      rootapp,
      jefetch,
      sharkshell,
      proton-cachyos,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      unstableConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [ "ventoy-1.1.17" "ventoy-1.1.12" ];
      };
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config = unstableConfig;
        };
      };
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      lmmsAppimageOverlay = lmms-appimage.overlays.default;
      musisharkOverlay = musishark.overlays.default;
      ruwaOverlay = ruwa.overlays.default;
      pandoraLauncherOverlay = pandora-launcher.overlays.default;
      rootappOverlay = rootapp.overlays.default;
      jefetchOverlay = jefetch.overlays.default;
      protonCachyosOverlay = proton-cachyos.overlays.default;

      sharedModules = [
        ({ ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
            http-connections = 50;
            auto-optimise-store = true;
            keep-outputs = true;
            keep-derivations = true;
            extra-substituters = [
              "https://attic.xuyh0120.win/lantian"
            ];
            extra-trusted-public-keys = [
              "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            ];
          };

          nixpkgs.overlays = [
            unstableOverlay
            helium-flake.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            lmmsAppimageOverlay
            pandoraLauncherOverlay
            rootappOverlay
            musisharkOverlay
            ruwaOverlay
            jefetchOverlay
            protonCachyosOverlay
          ];

          environment.systemPackages = [
            inputs.mocktail.packages.x86_64-linux.default
          ];
        })
      ];

      mkHost = machineModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          pkgsUnstable = import nixpkgs-unstable {
            inherit system;
            config = unstableConfig;
          };
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
      packages.x86_64-linux.zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.lmms-appimage = inputs.lmms-appimage.packages.x86_64-linux.default;
      packages.x86_64-linux.musishark = inputs.musishark.packages.x86_64-linux.default;
      packages.x86_64-linux.ruwa = inputs.ruwa.packages.x86_64-linux.default;
      packages.x86_64-linux.pandora-launcher = inputs.pandora-launcher.packages.x86_64-linux.default;
      packages.x86_64-linux.rootapp = inputs.rootapp.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
    };
}
