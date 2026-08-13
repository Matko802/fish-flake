{ ... }: {
  services.udev.extraRules = ''
    # Grant WebHID access to MCHOSE Mix 87-III
    KERNEL=="hidraw*", ATTRS{idVendor}=="3837", ATTRS{idProduct}=="300d", MODE="0666", TAG+="uaccess"
  '';
}
