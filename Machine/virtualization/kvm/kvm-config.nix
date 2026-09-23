{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    # Manual-only VM control via artixy /start /stop:
    # - onBoot="ignore" stops libvirt-guests from auto-starting guests
    #   that were running at shutdown (autostart=disable alone is not enough).
    # - onShutdown="shutdown" leaves guests shut off instead of suspended,
    #   so the next boot stays off until /start.
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      swtpm.enable = true;
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };
  };

  programs.virt-manager.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
  users.users."matko".extraGroups = [ "libvirtd" ];
}
