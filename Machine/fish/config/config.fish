if status is-interactive
end
starship init fish | source
set -U fish_greeting

function nh --wraps nh --description 'nh with automatic Metrolist input refresh'
    if test (count $argv) -ge 2; and test "$argv[1]" = os; and contains -- "$argv[2]" switch boot test
        if not string match -qr -- '^(--update-input|-U|--update|-u|--no-update-lock-file|--recreate-lock-file)' $argv
            command nh $argv[1] $argv[2] --update-input metrolist-kmp-flake $argv[3..-1]
            return $status
        end
    end
    command nh $argv
end
