{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    qtengine = {
      url = "github:kossLAN/qtengine";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sharkvis = {
      url = "github:Matko802/sharkvis";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    jefetch = {
      url = "github:Matko802/jefetch";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mocktail = {
      url = "git+https://github.com/komaruworld/mocktail?ref=main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    shark-scrp = {
      url = "github:Matko802/shark-scrp";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lmms-flake = {
      url = "github:Matko802/lmms-appimage-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    anker-launcher = {
      url = "github:Matko802/anker-launcher-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    ruwa = {
      url = "github:Matko802/ruwa";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    pandora-launcher = {
      url = "github:Matko802/PandoraLauncher-Flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rootapp = {
      url = "github:Matko802/rootapp-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    g3m = {
      url = "github:Matko802/g3m-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sharkshell = {
      url = "github:Matko802/sharkshell";
      flake = false;
    };
    proton-cachyos = {
      url = "github:Daaboulex/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mchose-hub = {
      url = "path:/mnt/ssd/My-Files/Projects/linux%20stuff/mchosehub-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    metrolist-kmp-flake = {
      url = "github:Matko802/metrolist-kmp-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      helium-flake,
      zen-browser,
      qtengine,
      sharkvis,
      mocktail,
      shark-scrp,
      lmms-flake,
      anker-launcher,
      ruwa,
      pandora-launcher,
      rootapp,
      g3m,
      jefetch,
      sharkshell,
      proton-cachyos,
      mchose-hub,
      metrolist-kmp-flake,
      nix-cachyos-kernel,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      opencodeManager = nixpkgs-unstable.legacyPackages.x86_64-linux.callPackage ./opencode/package.nix { };
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      lmmsFlakeOverlay = lmms-flake.overlays.default;
      ankerLauncherOverlay = anker-launcher.overlays.default;
      ruwaOverlay = ruwa.overlays.default;
      pandoraLauncherOverlay = pandora-launcher.overlays.default;
      rootappOverlay = rootapp.overlays.default;
      g3mOverlay = g3m.overlays.default;
      jefetchOverlay = jefetch.overlays.default;
      protonCachyosOverlay = proton-cachyos.overlays.default;
      metrolistKmpFlakeOverlay = metrolist-kmp-flake.overlays.default;

      sharedModules = [
        ({ ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
            http-connections = 50;
            auto-optimise-store = true;
            keep-outputs = true;
            keep-derivations = true;
            extra-substituters = [ "https://cache.lantian.pub/lantian" "https://cache.xinux.uz" ];
            extra-trusted-public-keys = [
              "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
              "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
            ];
          };

          nixpkgs.overlays = [
            helium-flake.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            lmmsFlakeOverlay
            ankerLauncherOverlay
            pandoraLauncherOverlay
            rootappOverlay
            g3mOverlay
            ruwaOverlay
            jefetchOverlay
            protonCachyosOverlay
            metrolistKmpFlakeOverlay
            nix-cachyos-kernel.overlays.pinned
          ];

          environment.systemPackages = [
            inputs.mocktail.packages.x86_64-linux.default
            opencodeManager
          ];
        })
      ];

      mkHost = machineModule: nixpkgs-unstable.lib.nixosSystem {
        inherit system;
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
      packages.x86_64-linux.sharkshell = (nixpkgs-unstable.legacyPackages.x86_64-linux.callPackage "${sharkshell}/packaging.nix" { }).sharkshell;
      packages.x86_64-linux.mocktail = inputs.mocktail.packages.x86_64-linux.default;
      packages.x86_64-linux.zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
      packages.x86_64-linux.shark-scrp = inputs.shark-scrp.packages.x86_64-linux.default;
      packages.x86_64-linux.lmms-flake = inputs.lmms-flake.packages.x86_64-linux.default;
      packages.x86_64-linux.anker-launcher = inputs.anker-launcher.packages.x86_64-linux.default;
      packages.x86_64-linux.ruwa = inputs.ruwa.packages.x86_64-linux.default;
      packages.x86_64-linux.pandora-launcher = inputs.pandora-launcher.packages.x86_64-linux.default;
      packages.x86_64-linux.rootapp = inputs.rootapp.packages.x86_64-linux.default;
      packages.x86_64-linux.g3m = inputs.g3m.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
      packages.x86_64-linux.metrolist-kmp-flake = inputs.metrolist-kmp-flake.packages.x86_64-linux.default.override {
        systemFont = self.nixosConfigurations.machine1.config.custom.fontName;
        waylandScale = builtins.toJSON self.nixosConfigurations.machine1.config.custom.waylandScale;
      };
      packages.x86_64-linux.opencode-manager = opencodeManager;
    };
}
