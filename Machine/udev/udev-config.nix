{ ... }: {
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="3837", ATTRS{idProduct}=="300d", MODE="0666", TAG+="uaccess"
  '';
}
