{ config, pkgs, ... }:

{
  # Enable COSMIC
  services.desktopManager.cosmic.enable = true;

  # Apply the COSMIC overlay
  nixpkgs.overlays = [
    (final: prev:
      let
        src = prev.fetchFromGitHub {
          owner = "salva09";
          repo = "nixpkgs";
          rev = "2a80dca18295869d5f9517587f916769e2d0d4f4";
          hash = "sha256-d/xa78MMTBAWJ64bpl8/2JtVGtIL56J+KoWP4fqlin0=";
        };

        byName = name: "${src}/pkgs/by-name/${builtins.substring 0 2 name}/${name}/package.nix";

        pkgNames = [
          "cosmic-applets"
          "cosmic-app-library"
          "cosmic-bg"
          "cosmic-comp"
          "cosmic-edit"
          "cosmic-files"
          "cosmic-greeter"
          "cosmic-icons"
          "cosmic-idle"
          "cosmic-initial-setup"
          "cosmic-launcher"
          "cosmic-notifications"
          "cosmic-osd"
          "cosmic-panel"
          "cosmic-player"
          "cosmic-randr"
          "cosmic-screenshot"
          "cosmic-session"
          "cosmic-settings"
          "cosmic-settings-daemon"
          "cosmic-store"
          "cosmic-term"
          "cosmic-wallpapers"
          "cosmic-workspaces-epoch"
          "xdg-desktop-portal-cosmic"
          "cosmic-protocols"
          "cosmic-monitor"
        ];
      in
      prev.lib.genAttrs pkgNames (
        name:
        (final.callPackage (byName name) { }).overrideAttrs (_: {
          doCheck = false;
        })
      )
    )
  ];
}