{ pkgs, ... }:

{
  systemd.user.services.artixy = {
    description = "artixy Discord bot";
    wantedBy = [ "default.target" ];

    path = with pkgs; [ libvirt grim ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.artixy}/bin/artixy";
      WorkingDirectory = "/mnt/ssd/My-Files/Projects/artixy";
      # No EnvironmentFile: token/vm live in ~/.config/artixy/config.toml.
      # (A mandatory EnvironmentFile pointing at a missing file fails the
      # unit with 'Result: resources'.)
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  users.users.matko.linger = true;
}
