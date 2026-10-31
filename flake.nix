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
    lmms-appimage = {
      url = "github:Matko802/lmms-appimage-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    musishark = {
      url = "github:Matko802/musishark";
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
    opencode = {
      url = "github:Matko802/opencode-flake";
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
    elasmo = {
      url = "github:Matko802/elasmo";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
      lmms-appimage,
      musishark,
      ruwa,
      pandora-launcher,
      rootapp,
      opencode,
      jefetch,
      sharkshell,
      proton-cachyos,
      mchose-hub,
      elasmo,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      sharkvisOverlay = sharkvis.overlays.default;
      sharkScrpOverlay = shark-scrp.overlays.default;
      lmmsAppimageOverlay = lmms-appimage.overlays.default;
      musisharkOverlay = musishark.overlays.default;
      ruwaOverlay = ruwa.overlays.default;
      pandoraLauncherOverlay = pandora-launcher.overlays.default;
      rootappOverlay = rootapp.overlays.default;
      opencodeOverlay = opencode.overlays.default;
      jefetchOverlay = jefetch.overlays.default;
      protonCachyosOverlay = proton-cachyos.overlays.default;
      elasmoOverlay = elasmo.overlays.default;

      sharedModules = [
        ({ ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
            http-connections = 50;
            auto-optimise-store = true;
            keep-outputs = true;
            keep-derivations = true;
            extra-substituters = [ "https://cache.xinux.uz" ];
            extra-trusted-public-keys = [
              "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
              "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
            ];
          };

          nixpkgs.overlays = [
            helium-flake.overlays.default
            sharkvisOverlay
            sharkScrpOverlay
            lmmsAppimageOverlay
            pandoraLauncherOverlay
            rootappOverlay
            opencodeOverlay
            musisharkOverlay
            ruwaOverlay
            elasmoOverlay
            jefetchOverlay
            protonCachyosOverlay
          ];

          environment.systemPackages = [
            inputs.mocktail.packages.x86_64-linux.default
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
      packages.x86_64-linux.lmms-appimage = inputs.lmms-appimage.packages.x86_64-linux.default;
      packages.x86_64-linux.musishark = inputs.musishark.packages.x86_64-linux.default;
      packages.x86_64-linux.ruwa = inputs.ruwa.packages.x86_64-linux.default;
      packages.x86_64-linux.pandora-launcher = inputs.pandora-launcher.packages.x86_64-linux.default;
      packages.x86_64-linux.rootapp = inputs.rootapp.packages.x86_64-linux.default;
      packages.x86_64-linux.opencode = inputs.opencode.packages.x86_64-linux.default;
      packages.x86_64-linux.jefetch = inputs.jefetch.packages.x86_64-linux.default;
    };
}
