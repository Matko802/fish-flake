{
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2dc8", MODE="0666", GROUP="users", TAG+="uaccess"
  '';
}
