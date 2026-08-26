{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  programs.virt-manager.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  environment.systemPackages = [
    pkgs.dnsmasq
  ];
  users.users."matko".extraGroups = [ "libvirtd" ];
}
