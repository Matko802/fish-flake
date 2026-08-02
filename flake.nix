{
  description = "Matko's NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    helium-flake.url = "github:oxcl/nix-flake-helium-browser";
    helium-flake.inputs.nixpkgs.follows = "nixpkgs";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    gsr-ui-nix = {
      url = "github:rPlakama/gsr-ui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qtengine = {
      url = "github:kossLAN/qtengine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  outputs = { nix-cachyos-kernel, self, nixpkgs, helium-flake, ... }@inputs: {
    nixosConfigurations.matko = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./configuration.nix
        ./user.nix

        (
          { pkgs, ... }:

          {
            nixpkgs.overlays = [
              helium-flake.overlays.default
              nix-cachyos-kernel.overlays.pinned
            ];

            environment.systemPackages = [ pkgs.helium ];

            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
          }
        )
      ];
    };
  };
}
