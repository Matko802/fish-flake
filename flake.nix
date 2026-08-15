{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    helium-flake.url = "github:oxcl/nix-flake-helium-browser";
    helium-flake.inputs.nixpkgs.follows = "nixpkgs";
    gsr-ui-nix = {
      url = "github:rPlakama/gsr-ui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qtengine = {
      url = "github:kossLAN/qtengine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs =
    {
      self,
      nixpkgs,
      helium-flake,
      waybar,
      ...
    }@inputs:
    let
      # cavis: cava-inspired terminal spectrum analyzer (C, pulseaudio input)
      cavisOverlay = final: prev: {
        cavis = prev.stdenv.mkDerivation {
          pname = "cavis";
          version = "0.1.0";
          src = ./cavis;
          nativeBuildInputs = [ prev.pkg-config ];
          buildInputs = [ prev.libpulseaudio ];
          makeFlags = [ "PREFIX=$(out)" ];
          meta = {
            mainProgram = "cavis";
            description = "Terminal audio spectrum analyzer";
          };
        };
      };

      sharedModules = [

        ({ pkgs, ... }: {
          nix.settings = {
            max-jobs = "auto";
            cores = 0;
          };

          nixpkgs.overlays = [
            waybar.overlays.default
            helium-flake.overlays.default
            cavisOverlay
          ];

          environment.systemPackages = [ pkgs.helium ];
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
      packages.x86_64-linux.cavis = (import nixpkgs {
        system = "x86_64-linux";
        overlays = [ cavisOverlay ];
      }).cavis;
    };
}