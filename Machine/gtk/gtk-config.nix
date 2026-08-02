{ config, ... }: {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/gtk-3.0 0755 ${config.users.users.matko.name} users -"
    "d ${config.users.users.matko.home}/.config/gtk-4.0 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/gtk-3.0/settings.ini - - - - ${./config/gtk-3.0/settings.ini}"
    "L+ ${config.users.users.matko.home}/.config/gtk-3.0/gtk.css - - - - ${./config/gtk-3.0/gtk.css}"
    "L+ ${config.users.users.matko.home}/.config/gtk-4.0/settings.ini - - - - ${./config/gtk-4.0/settings.ini}"
    "L+ ${config.users.users.matko.home}/.config/gtk-4.0/gtk.css - - - - ${./config/gtk-4.0/gtk.css}"
    "L+ ${config.users.users.matko.home}/.themes/MatkosAmoled - - - - ${./theme/MatkosAmoled}"
  ];
}
