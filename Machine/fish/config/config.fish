if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias refish="sudo nixos-rebuild switch --flake /home/matko/fish-flake#matko";
starship init fish | source
set -U fish_greeting
