# No greeting (fish: `set -U fish_greeting`)
$env.config = ($env.config | upsert show_banner false)

# Starship prompt (fish: `starship init fish | source`)
if (which starship | is-not-empty) {
  mkdir ($nu.data-dir | path join "vendor/autoload")
  starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
}
