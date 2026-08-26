{ ... }:

{
  virtualisation.virtualbox.host.enable = true;
  users.users."matko".extraGroups = [ "vboxusers" ];
}
