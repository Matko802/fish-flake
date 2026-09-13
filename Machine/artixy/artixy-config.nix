{ pkgs, ... }:

{
  systemd.user.services.artixy = {
    description = "artixy Discord bot";
    wantedBy = [ "default.target" ];

    path = with pkgs; [ libvirt grim ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.artixy}/bin/artixy";
      WorkingDirectory = "/home/matko/artixy";
      EnvironmentFile = "/home/matko/artixy/.env";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  users.users.matko.linger = true;
}
