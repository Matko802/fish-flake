{ ... }: {
  services.udev.extraRules = ''
    # Grant WebHID access to MCHOSE Mix 87-III
    KERNEL=="hidraw*", ATTRS{idVendor}=="3837", ATTRS{idProduct}=="300d", MODE="0666", TAG+="uaccess"

    # Wake from suspend with keyboard/mouse. The HID devices allow wakeup,
    # but the USB root hubs in front of them default to disabled and swallow
    # the signal before it reaches the CPU.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="3837", ATTR{idProduct}=="300d", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c53f", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"

    # Treat the secondary SATA SSD as a user drive so GNOME apps
    # (Baobab, Nautilus, …) list it instead of hiding it as a system disk.
    SUBSYSTEM=="block", ENV{ID_FS_UUID}=="5985a5cc-6808-46fa-ac5a-f321e2838c8f", ENV{UDISKS_SYSTEM}="0"
  '';
}
