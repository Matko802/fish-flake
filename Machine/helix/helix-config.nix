{ pkgs, ... }: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        bufferline = "multiple";
        color-modes = true;
        true-color = true;
        lsp.display-messages = true;
        indent-guides = {
          render = true;
          character = "│";
          skip-levels = 1;
        };
        whitespace.render = {
          space = "none";
          tab = "all";
          nbsp = "all";
          newline = "none";
        };
      };
      theme = "catppuccin_mocha";
      keys.normal = {
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
        space = {
          f = "file_picker";
          b = "buffer_picker";
          "/" = "global_search";
          y = ":clipboard-yank";
          p = ":clipboard-paste-after";
          P = ":clipboard-paste-before";
        };
      };
      keys.insert = {
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
      };
    };
    languages = {
      language-server.nil = {
        command = "nil";
      };
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = { command = "nixfmt"; };
          language-servers = [ "nil" ];
        }
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "python";
          auto-format = true;
          language-servers = [ "pyright" "ruff" ];
        }
        {
          name = "javascript";
          auto-format = true;
          language-servers = [ "ts-ls" ];
        }
        {
          name = "typescript";
          auto-format = true;
          language-servers = [ "ts-ls" ];
        }
        {
          name = "toml";
          auto-format = true;
        }
        {
          name = "json";
          auto-format = true;
        }
        {
          name = "markdown";
          auto-format = true;
          soft-wrap.enable = true;
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    nil
    nixfmt-rfc-style
    marksman
  ];
}
