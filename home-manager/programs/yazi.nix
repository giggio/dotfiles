{ pkgs, ... }:

{
  programs.yazi = {
    # File manager with minimalistic curses interface https://ranger.github.io/
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    plugins = with pkgs.yaziPlugins; {
      inherit starship piper git;
    };
    initLua = /* lua */ ''
      			require("starship"):setup({
      				config_file = "~/.config/yazi/starship.toml",
            })
            require("git"):setup({
            	order = 1500,
            })
    '';
    settings = {
      "$schema" = "https://yazi-rs.github.io/schemas/yazi.json";
      mgr = {
        linemode = "size";
        show_hidden = true;
        show_symlink = true;
        scrolloff = 5;
        title_format = "Yazi: {cwd}";
      };
      opener = {
        edit = [
          {
            run = "${"EDITOR:-nvim"} %s";
            desc = "$EDITOR";
            for = "unix";
            block = true;
          }
          {
            run = "nvim %s";
            desc = "code";
            for = "windows";
            block = true;
          }
        ];
        play = [
          {
            run = "xdg-open %s1";
            desc = "Play";
            for = "linux";
            orphan = true;
          }
          {
            run = "start \"\" %s1";
            desc = "Play";
            for = "windows";
            orphan = true;
          }
          {
            run = "termux-open %s1";
            desc = "Play";
            for = "android";
          }
          {
            run = "mediainfo %s1; echo 'Press enter to exit'; read _";
            block = true;
            desc = "Show media info";
            for = "unix";
          }
          {
            run = "mediainfo %s1 & pause";
            block = true;
            desc = "Show media info";
            for = "windows";
          }
        ];
        open = [
          {
            run = "xdg-open %s1";
            desc = "Open";
            for = "linux";
          }
          {
            run = "start \"\" %s1";
            desc = "Open";
            for = "windows";
            orphan = true;
          }
          {
            run = "termux-open %s1";
            desc = "Open";
            for = "android";
          }
        ];
        nav = [
          {
            run = "ya emit cd %S";
            desc = "Navigate to";
          }
        ];
        reveal = [
          {
            run = "xdg-open %d1";
            desc = "Reveal";
            for = "linux";
          }
          {
            run = "explorer /select,%s1";
            desc = "Reveal";
            for = "windows";
            orphan = true;
          }
          {
            run = "termux-open %d1";
            desc = "Reveal";
            for = "android";
          }
          {
            run = "clear; exiftool %s1; echo 'Press enter to exit'; read _";
            desc = "Show EXIF";
            for = "unix";
            block = true;
          }
        ];
        extract = [
          {
            run = "ya pub extract --list %s";
            desc = "Extract here";
          }
        ];
        download = [
          {
            run = "ya emit download --open %S";
            desc = "Download and open";
          }
          {
            run = "ya emit download %S";
            desc = "Download";
          }
        ];
      };
      open = {
        prepend_rules = [
          {
            url = "*/";
            use = [ "nav" ];
          }
        ];
      };
      plugin = {

        prepend_fetchers = [
          {
            id = "mime";
            url = "**/onedrive/";
            run = "noop";
            prio = "high";
          }
          {
            id = "mime";
            url = "**/onedrive/**/";
            run = "noop";
            prio = "high";
          }
          {
            id = "mime";
            url = "**/onedrive/**/*";
            run = "noop";
            prio = "high";
          }
          {
            id = "git";
            url = "*";
            run = "git";
            prio = "high";
          }
          {
            id = "git";
            url = "*/";
            run = "git";
            prio = "high";
          }
        ];

        prepend_spotters = [
          {
            url = "**/onedrive/";
            run = "noop";
          }
          {
            url = "**/onedrive/**/";
            run = "noop";
          }
          {
            url = "**/onedrive/**/*";
            run = "noop";
          }
        ];
        prepend_preloaders = [
          {
            url = "**/onedrive/**/*";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "noop";
          }
        ];
        prepend_previewers = [
          {
            url = "**/onedrive/";
            run = "noop";
          }
          {
            url = "**/onedrive/**/";
            run = "noop";
          }
          {
            url = "**/onedrive/**/*";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "noop";
          }
          {
            mime = "image/*";
            run = "noop";
          }

          {
            url = "*.md";
            run = ''piper -- rich --emoji --left --panel=rounded --guides --line-numbers --force-terminal "$1" 2>/dev/null'';
          }
          {
            url = "*.csv";
            run = ''piper -- rich --left --panel=rounded --guides --line-numbers --force-terminal "$1" 2>/dev/null'';
          }
          {
            url = "*.rst";
            run = ''piper -- rich --left --panel=rounded --guides --line-numbers --force-terminal "$1" 2>/dev/null'';
          }
          {
            url = "*.ipynb";
            run = ''piper -- rich --left --panel=rounded --guides --line-numbers --force-terminal "$1" 2>/dev/null'';
          }
        ];
      };
    };
    keymap = {
      "$schema" = "https://yazi-rs.github.io/schemas/keymap.json";
      mgr = {
        prepend_keymap = [
          {
            on = "/";
            run = "find --previous --smart";
            desc = "Find previous file";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
          {
            on = "~";
            run = "noop";
          }
        ];
      };
      tasks = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      spot = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      pick = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      input = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      confirm = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      cmp = {
        prepend_keymap = [
          {
            on = "~";
            run = "noop";
          }
          {
            on = "?";
            run = "help";
            desc = "Open help";
          }
        ];
      };
      help = {
        prepend_keymap = [
          {
            on = "q";
            run = "escape";
            desc = "Clear the filter, or hide the help";
          }
          {
            on = "/";
            run = "filter";
            desc = "Filter help items";
          }
        ];
      };
    };
    theme = {
      mgr = {
        syntect_theme = "~/.config/yazi/material.tmTheme";
      };
      manager = {
        cwd = {
          fg = "#89ddff";
        };
        hovered = {
          fg = "#eeffff";
          bg = "#263238";
        };
        preview_hovered = {
          bg = "#1a1a1a";
        };
        selected = {
          fg = "#eeffff";
          bg = "#37474f";
        };
        find_keyword = {
          fg = "#ffcb6b";
          italic = true;
        };
        find_position = {
          fg = "#f07178";
          bg = "reset";
          italic = true;
        };
        marker = {
          fg = "#82aaff";
          bg = "#82aaff";
        };
        tab_active = {
          fg = "#000000";
          bg = "#80cbc4";
        };
        tab_inactive = {
          fg = "#eeffff";
          bg = "#121212";
        };
        border = {
          fg = "#424242";
        };
      };
      status = {
        separator_open = "";
        separator_close = "";
        main = {
          fg = "#000000";
          bg = "#80cbc4";
        };
        secondary = {
          fg = "#eeffff";
          bg = "#263238";
        };
        tertiary = {
          fg = "#eeffff";
          bg = "reset";
        };
      };
      input = {
        border = {
          fg = "#82aaff";
        };
        title = {
          fg = "#82aaff";
        };
        value = {
          fg = "#eeffff";
        };
      };
      filetype = {
        rules = [
          {
            url = "*/";
            fg = "#82aaff";
          }
          {
            url = "*";
            is = "orphan";
            fg = "#f07178";
            bg = "reset";
          }
          {
            url = "*";
            is = "exec";
            fg = "#c3e88d";
          }
          {
            url = "*";
            is = "dummy";
            bg = "#f07178";
          }
          {
            mime = "image/*";
            fg = "#ffcb6b";
          }
          {
            mime = "{audio,video}/*";
            fg = "#c792ea";
          }
          {
            mime = "application/{zip,rar,7z*,tar,gzip,bzip2,xz,zstd,lz4,lzma}";
            fg = "#f78c6c";
          }
          {
            mime = "application/pdf";
            fg = "#f07178";
          }
          {
            is = "link";
            fg = "#89ddff";
          }
          {
            url = "*";
            fg = "#eeffff";
          }
          {
            url = "*/";
            is = "dummy";
            bg = "#f07178";
          }
        ];
      };
      select = {
        border = {
          fg = "#82aaff";
        };
        active = {
          fg = "#c792ea";
        };
        inactive = {
          fg = "#eeffff";
        };
      };
      tasks = {
        border = {
          fg = "#82aaff";
        };
        title = {
          fg = "#82aaff";
        };
        hovered = {
          fg = "#c792ea";
          underline = true;
        };
      };
      which = {
        mask = {
          bg = "#1a1a1a";
        };
        cand = {
          fg = "#89ddff";
        };
        rest = {
          fg = "#546e7a";
        };
        desc = {
          fg = "#c792ea";
        };
        separator = "  ";
      };
      notify = {
        title_info = {
          fg = "#c3e88d";
        };
        title_warn = {
          fg = "#ffcb6b";
        };
        title_error = {
          fg = "#f07178";
        };
      };
    };
  };
}
