{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
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
    cz-agent-gui = {
      url = "path:/mnt/ssd/My-Files/Projects/cz-agent-gui-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sharkshell = {
      url = "github:Matko802/sharkshell";
      flake = false;
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
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
      helium-flake,
      zen-browser,
      sharkvis,
      mocktail,
      shark-scrp,
      lmms-appimage,
      musishark,
      ruwa,
      pandora-launcher,
      rootapp,
      cz-agent-gui,
      jefetch,
      sharkshell,
      nix-cachyos-kernel,
      proton-cachyos,
      ...
    }@inputs:
    let
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      lmmsAppimageOverlay = lmms-appimage.overlays.default;
      musisharkOverlay = musishark.overlays.default;
      ruwaOverlay = ruwa.overlays.default;
      pandoraLauncherOverlay = pandora-launcher.overlays.default;
      rootappOverlay = rootapp.overlays.default;
      czAgentGuiOverlay = cz-agent-gui.overlays.default;
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
            helium-flake.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            lmmsAppimageOverlay
            pandoraLauncherOverlay
            rootappOverlay
            czAgentGuiOverlay
            musisharkOverlay
            ruwaOverlay
            jefetchOverlay
            nix-cachyos-kernel.overlays.pinned
            protonCachyosOverlay
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
      packages.x86_64-linux.zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.lmms-appimage = inputs.lmms-appimage.packages.x86_64-linux.default;
      packages.x86_64-linux.musishark = inputs.musishark.packages.x86_64-linux.default;
      packages.x86_64-linux.ruwa = inputs.ruwa.packages.x86_64-linux.default;
      packages.x86_64-linux.pandora-launcher = inputs.pandora-launcher.packages.x86_64-linux.default;
      packages.x86_64-linux.rootapp = inputs.rootapp.packages.x86_64-linux.default;
      packages.x86_64-linux.cz-agent-gui = inputs.cz-agent-gui.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
    };
}
