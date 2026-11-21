{ config, lib, pkgs, ... }: {
  options.custom.waylandScale = lib.mkOption {
    type = lib.types.float;
    default = 1.2;
    description = "Wayland output scale, used by XWayland/Compose apps that cannot detect niri";
  };

  config = {
    programs.niri.enable = true;

    environment.systemPackages = with pkgs; [
      wl-clipboard
      xwayland-satellite
      playerctl
      satty
      libnotify
      cliphist
      (hyprpicker.overrideAttrs (old: {
        version = "0.4.7";
        src = fetchFromGitHub {
          owner = "hyprwm";
          repo = "hyprpicker";
          tag = "v0.4.7";
          hash = "sha256-ABumeksE8Bvtdb6g4vJ2jA9BLlYHnXU86VAuKJhBPoY=";
        };
      }))
      snixembed
    ];

    systemd.tmpfiles.rules = [
      "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
      "L+ ${config.users.users.matko.home}/.config/niri - - - - ${./config}"
    ];
  };
}
