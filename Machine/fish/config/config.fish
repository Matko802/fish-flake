if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias refish="sudo nixos-rebuild switch --flake /home/matko/fish-flake#matko";
alias gitfix="cd /home/matko/fish-flake && git add . && git commit -m 'Update system configuration' && git push origin main"
starship init fish | source
set -U fish_greeting
