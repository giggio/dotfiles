{ config, pkgs, pkgs-stable, lib, inputs, setup, ... }:

let
  # todo: move shellSessionVariables somewhere else when https://github.com/nix-community/home-manager/issues/5474 is fixed
  # but, be careful, this is used by nushell and bash (.bashrc)
  shellSessionVariables = {
    DOCKER_BUILDKIT = "1";
    DOTNET_ROOT = "${pkgs.dotnet-sdk}";
    FZF_DEFAULT_COMMAND = "'fd --type file --color=always --exclude .git'";
    FZF_DEFAULT_OPTS = "--ansi";
    FZF_CTRL_T_COMMAND = ''"$FZF_DEFAULT_COMMAND"'';
  };
in
rec {
  imports = (if setup.wsl then [
  ] else [
    ./dconf/dconf.nix
    ./virtualbox.nix
  ]);

  nixpkgs = {
    config = {
      rocmSupport = true; # used by ollama and maybe others
      allowUnfreePredicate = pkg: builtins.elem (lib.strings.getName pkg) [
        "code"
        "discord"
        "gh-copilot"
        "microsoft-edge-stable"
        "mqtt-explorer"
        "obsidian"
        "slack"
        "terraform"
        "vault"
        "vscode"
        "ookla-speedtest"
      ];
    };
    overlays = [
      inputs.fenix.overlays.default # rust toolchain
      (final: prev: (import ./pkgs/default.nix { pkgs = prev; }))
      # todo: remove patch when https://github.com/nix-community/dconf2nix/pull/95 is released and gets merged into nixpkgs
      # check if https://github.com/nix-community/dconf2nix/releases/latest is > 0.1.1
      # and https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/tools/haskell/dconf2nix/dconf2nix.nix
      (final: prev:
        {
          dconf2nix = prev.dconf2nix.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (builtins.fetchurl {
                url = "https://github.com/nix-community/dconf2nix/compare/2fc3b0dfbbce9f1ea2ee89f3689a7cb95b33b63f...e7e5187d4a738ad1b551f97de3fa9766b7d92167.patch";
                sha256 = "sha256:0f1jn8xff6vk1w7x3l7lr5w18ki0az3rn2ihchgzzn0yszkk5g4d";
              })
            ];
          });
        })
    ];
  };

  home = {
    username = "giggio";
    homeDirectory = "/home/" + home.username;
    stateVersion = "26.05"; # Check if there are state version changes before changing this fiels: https://nix-community.github.io/home-manager/release-notes.xhtml
    preferXdgDirectories = true;
    pointerCursor = {
      gtk.enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 22;
    };
    packages = import ./pkgs.nix { inherit config; inherit pkgs; inherit pkgs-stable; inherit lib; inherit setup; };

    shell = {
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };

    # Home Manager can also manage your environment variables through
    # 'sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    sessionPath = [
      "$HOME/.local/bin"
      "$XDG_DATA_HOME/npm/bin"
      "$HOME/.krew/bin"
    ];
    sessionVariables = {
      # this goes into ~/.nix-profile/etc/profile.d/hm-session-vars.sh, which is
      # loaded by .profile, and so only reloads if we logout and log back in
      LC_ALL = "en_US.UTF-8";
      TMP = "/tmp";
      TEMP = "/tmp";
      EDITOR = "nvim";
      XDG_DATA_HOME = "\${XDG_DATA_HOME:-$HOME/.local/share}";
      XDG_STATE_HOME = "\${XDG_STATE_HOME:-$HOME/.local/state}";
      XDG_CACHE_HOME = "\${XDG_CACHE_HOME:-$HOME/.cache}";
      NPM_CONFIG_PREFIX = "\${NPM_CONFIG_PREFIX:-$HOME/.local/share/npm}";
      BASIC_SETUP = "\${BASIC_SETUP:-false}";
    };
    sessionVariablesExtra = lib.mkOrder 2000 ''
      # this is from sessionVariablesExtra, and is loaded at the very end hm-session-vars.sh
    '';

    file = {
      ".cargo/.keep".text = "";
      ".local/bin/dotnet-uninstall".source = ./bin/dotnet-uninstall;
      ".local/bin/hm".source = ./bin/hm;
      ".local/bin/sm".source = ./bin/sm;
      ".local/bin/updatedb_local".source = ./bin/updatedb_local;
      ".hushlogin".text = "";
      ".XCompose".source = "${pkgs.custom-xcompose}/lib/.XCompose";
      ".tmux.conf".text =
        ''
          set -g default-terminal "screen-256color"
          set-option -g default-shell /bin/bash
          set -g history-limit 10000
          source "$HOME/.nix-profile/share/tmux/powerline.conf"
          set -g status-bg colour233
          set-option -g status-position top
          set -g mouse

          # Smart pane switching with awareness of vim splits
          bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)g?(view|vim?)(diff)?$' && tmux send-keys C-h) || tmux select-pane -L"
          bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)g?(view|vim?)(diff)?$' && tmux send-keys C-j) || tmux select-pane -D"
          bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)g?(view|vim?)(diff)?$' && tmux send-keys C-k) || tmux select-pane -U"
          bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)g?(view|vim?)(diff)?$' && tmux send-keys C-l) || tmux select-pane -R"
          # bind -n C-\ run "(tmux display-message -p '#{pane_current_command}' | grep -iqE '(^|\/)g?(view|vim?)(diff)?$' && tmux send-keys 'C-\\') || tmux select-pane -l"
        '';
      ".w3m/config".text =
        ''
          inline_img_protocol 4
          auto_image TRUE
        '';
      ".inputrc".text =
        ''
          set bell-style none
          # reset the screen with Ctrl+L, normal CTRL+L in Kitty will not clear the scrollback
          "\C-l":"\C-k \C-utput reset\n"
        '';
      ".vimrc".text = "source ~/.vim/init.vim";
    };

  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
    };
  };

  programs = {
    home-manager = {
      # Let Home Manager install and manage itself.
      enable = true;
    };

    bash = {
      enable = true;
      initExtra = lib.mkMerge [
        ''
          # end of nix configuration

          # ending of .bashrc:
          if [ -f "$HOME"/.cargo/env ]; then
            source "$HOME/.cargo/env"
          fi
          if [[ $TERM != "dumb" ]]; then
            eval "$(starship init bash)"
          fi
          export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
          if [ -d "$HOME/.kube" ]; then
            KUBECONFIG=`find "$HOME"/.kube -maxdepth 1 -type f ! -name '*.bak' ! -name '*.backup' ! -name kubectx | sort | paste -sd ":" -`
            export KUBECONFIG
          fi
          function gitignore () {
            if [ -v 1 ]; then
              case "$1" in
                -v|--version|-h|--help|-l|--list)
                git-ignore "$@"
                ;;
                *)
                git-ignore "$@" > .gitignore
                ;;
              esac
            else
              git-ignore -a > .gitignore
            fi
          }
          # setup ssh socket
          if $WSL; then
            # forward ssh socket to Windows
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/ssh.sock"
          else
            # deal with ssh socket forwarding to gpg or using ssh-agent
            source "${ ./bash/ssh-socket.bash }"
          fi
          # auto complete all aliases
          complete -F _complete_alias "''${!BASH_ALIASES[@]}"

          [[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path bash)"

          export LOCATE_PATH=$XDG_CACHE_HOME/mlocate.db

          source "${ ./bash/aliases-and-functions.bash }"

          source "$(blesh-share)/ble.sh"
          # end of .bashrc

          # beginning of configurations coming from other options, like gpg-agent, direnv and zoxide
        ''
        (lib.mkOrder 10000
          ''
            # very end of .bashrc
            export PATH="$(printf '%s\n' "$HOME/.local/bin:$PATH" | tr ':' '\n' | awk '!seen[$0]++' | paste -sd: -)"
          '')
      ];
      logoutExtra =
        ''
          # when leaving the console clear the screen to increase privacy
          if [ "$SHLVL" = 1 ]; then
            [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
          fi
        '';
      profileExtra =
        ''
          # beginning of .profile
          umask 022
          if ! [ -v XDG_RUNTIME_DIR ]; then
            XDG_RUNTIME_DIR=/run/user/`id -u`/
            export XDG_RUNTIME_DIR
            if ! [ -d "$XDG_RUNTIME_DIR" ]; then
              mkdir -p "$XDG_RUNTIME_DIR"
              chmod 755 "$XDG_RUNTIME_DIR"
            fi
          fi
          # ending of .profile
        '';
      historySize = -1;
      historyFileSize = -1;
      historyFile = "$HOME/.bash_history2";
      historyControl = [ "ignoreboth" ];
      sessionVariables = {
        # this goes to .profile, and only reloads if we logout and log back in
        # it should go to .bashrc, but it's not possible to set it there
        # see: https://github.com/nix-community/home-manager/issues/5474
        # move `shellSessionVariables` here this issue closes and this starts to go to .bashrc
        # but, carefully, `shellSessionVariables` is used by nushell and bash
      };
      shellAliases =
        let
          nonWsl = if setup.wsl then { } else {
            clip = "xclip -selection clipboard";
          };
          wslOnly = if setup.wsl then { } else { };
          common = {
            start = "xdg-open";
            trash = "trash-put";
            "??" = "ollama run --keepalive=-1s linus"; # see https://github.com/giggio/ollama_models
            "?rs" = "ollama run --keepalive=-1s furry"; # see https://github.com/giggio/ollama_models
            "?bash" = "gh-copilot suggest -t shell";
            "?gh" = "gh-copilot suggest -t gh";
            "?git" = "gh-copilot suggest -t git";
            ls = "ls --color=auto --hyperlink=always";
            dir = "dir --color=auto";
            vdir = "vdir --color=auto";
            grep = "grep --color=auto";
            fgrep = "fgrep --color=auto";
            egrep = "egrep --color=auto";
            ll = "eza --long --group --all --all --group-directories-first --hyperlink";
            la = "ls -A";
            l = "ls -CF";
            cls = "clear";
            alert = ''notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e ";\";";s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//";\";";)"'';
            add = "git add";
            st = "git status";
            log = "git log";
            ci = "git commit";
            push = "git push";
            pushf = "git push --force-with-lease";
            co = "git checkout";
            pull = "git pull";
            fixup = "git fixup";
            dif = "git diff";
            pushsync = "git push --set-upstream origin `git rev-parse --abbrev-ref HEAD`";
            # git = "hub"; # now using a function, see ./bash/aliases-and-functions.bash
            istio = "istioctl";
            tf = "terraform";
            "cd-" = "cd -";
            "cd.." = "cd ..";
            "cd..." = "cd ../..";
            "cd...." = "cd ../../..";
            weather = "curl -s wttr.in";
            toyaml = "bat --language yaml";
            ghce = "gh-copilot explain";
            ghcs = "gh-copilot suggest";
            mg = "kitty +kitten hyperlinked_grep --smart-case";
            keys = "dconf dump /org/gnome/desktop/wm/keybindings/";
            cdr = "cd `git rev-parse --show-toplevel 2> /dev/null || echo '.'`";
            update = "sudo apt update; apt list --upgradable";
            upgrade = "apt list --upgradable; sudo apt upgrade -y; apt list --upgradable; [ -f /var/run/reboot-required ] && echo -e '\e[31mReboot required.\e[0m' || echo -e '\e[32mNo need to reboot.\e[0m'";
            kubectl = "kubecolor";
            http = "xh";
            vim = "nvim";
            vi = "nvim";
            cl = "tput clear";
          };
        in
        nonWsl // wslOnly // common;
      shellOptions = [
        "histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"
      ];
      bashrcExtra =
        let
          bashSessionVariables = {
            # environment variables to add only to .bashrc
            PATH = "$HOME/.local/bin:$PATH"; # this is here so it is added before the other paths
            NAVI_PATH = "${config.home.profileDirectory}/share/navi/cheats/common/:${config.home.profileDirectory}/share/navi/cheats/bash/:${config.home.profileDirectory}/share/navi/cheats/linux/common/:${config.home.profileDirectory}/share/navi/cheats/linux/bash/";
            LUA_PATH = "\"${pkgs.mylua}/share/lua/5.1/?.lua;${pkgs.mylua}/share/lua/5.1/?/init.lua;$HOME/.luarocks/share/lua/5.1/?.lua;$HOME/.luarocks/share/lua/5.1/?/init.lua;$LUA_PATH;;\"";
            LUA_CPATH = "\"${pkgs.mylua}/lib/lua/5.1/?.so;$HOME/.luarocks/lib/lua/5.1/?.so;$LUA_CPATH;;\"";
          };
        in
        lib.concatStringsSep "\n" (lib.concatLists [
          [
            ''
              # beginning of .bashrc

              # Shell session variables:
            ''
          ]
          (lib.mapAttrsToList (k: v: "export ${k}=${v}") shellSessionVariables)
          [
            ''

              # Bash session variables:
            ''
          ]
          (lib.mapAttrsToList (k: v: "export ${k}=${v}") bashSessionVariables)
          [
            ''

              # beginning of .bashrc config
              unset MAILCHECK
              # If not running interactively, don't do anything
              [[ $- == *i* ]] || return
              # configure vi mode
              set -o vi
              bind '"jj":"\e"'
              tabs -4
              bind 'set completion-ignore-case on'
              source ${pkgs.kubectl-aliases}/bin/kubectl_aliases.bash
              source ${pkgs.complete-alias}/bin/complete_alias
              source "$HOME/.dotfiles/bashscripts/.bashrc"
              if [ -d ~/.luarocks/bin ]; then
                export PATH="$PATH:$HOME/.luarocks/bin"
              fi
              # make less more friendly for non-text input files, see lesspipe(1)
              [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
              eval "$(navi widget bash)"

              # beginning of nix configuration
            ''
          ]
        ]
        );
    };

    nushell = {
      enable = true;
      extraConfig =
        ''
          # beginning of extra nushell configuration
          source ${home.homeDirectory}/.dotfiles/nuscripts/config.nu
          # end of extra nushell configuration
        '';
      extraEnv =
        ''
          # beginning of extra nushell environment
          source ${home.homeDirectory}/.dotfiles/nuscripts/env.nu
          # end of extra nushell environment
        '';
      extraLogin =
        ''
          # beginning of extra nushell login
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "$env.${k} = \"${v}\"") shellSessionVariables)}
          # end of extra nushell login
        '';
    };

    # Ideally we'd be able to set where to initalize Starship, but by default it is added to the end of the .bashrc
    # file. This causes it to run after `history -a`, and then Starship is not able to show the exit status of
    # the last command. To fix this, we set the `PROMPT_COMMAND` variable to run `history -a` before Starship,
    # which is started manually in the .bashrc file. See bellow
    starship.enable = false;

    gpg = {
      enable = true;
      publicKeys = [
        {
          source = ./gpg/giggio.pub; # https://links.giggio.net/pgp
          trust = "ultimate";
        }
      ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };

    zoxide = {
      enable = true;
    };

    atuin = {
      enable = true;
      daemon.enable = false;
      settings = {
        # https://docs.atuin.sh/configuration/config/
        search_mode = "skim";
        workspaces = true;
        inline_height = 0;
        enter_accept = true;
      };
    };

    librewolf = {
      enable = !setup.wsl;
      package = pkgs.librewolf-bin;
      languagePacks = [ "en-US" "pt-BR" ];
      nativeMessagingHosts = [
        pkgs.gnome-browser-connector
        pkgs.bitwarden-desktop
      ];
    };

    zapzap = {
      enable = !setup.wsl;
      package = pkgs.zapzap;
    };
  };

  fonts.fontconfig.enable = !setup.wsl;

  xdg = {
    configFile = {
      "autostart/bitwarden.desktop" = {
        enable = !setup.wsl;
        source = "${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop";
      };
      "autostart/kitty.desktop" = {
        enable = !setup.wsl;
        text = builtins.replaceStrings [ "\nExec=kitty" ] [ "\nExec=kitty --title main" ]
          (builtins.readFile "${pkgs.kitty}/share/applications/kitty.desktop");
      };
      "autostart/activitywatch.desktop" = {
        enable = !setup.wsl;
        source = "${pkgs.activitywatch}/share/applications/aw-qt.desktop";
      };
      "autostart/forge-sparks.desktop" = {
        enable = !setup.wsl;
        text =
          ''
            [Desktop Entry]
            Name=Forge Sparks
            Exec=forge-sparks --hidden
            Type=Application
            StartupNotify=true
            Terminal=false
            Icon=com.mardojai.ForgeSparks
          '';
      };
      "burn-my-windows/profiles/close.conf".source = ./dconf/cfg/burn-close.conf;
      "burn-my-windows/profiles/burn-app-edge.conf".source = ./dconf/cfg/burn-app-edge.conf;
      "burn-my-windows/profiles/open.conf".source = ./dconf/cfg/burn-open.conf;
      "burn-my-windows/profiles/burn-app-brave.conf".source = ./dconf/cfg/burn-app-brave.conf;
      "alacritty".source = ./config/alacritty;
      "navi/config.yaml".source = ./config/navi-config.yaml;
      "terminator/config".source = ./config/terminator-config;
      "starship.toml".source = ./config/starship.toml;
      "git".source = ./config/git;
      "carapace/bridges.yaml".source = ./config/carapace/bridges.yaml;
      "carapace/overlays".source = ./config/carapace/overlays;
      "carapace/specs".source = ./config/carapace/specs;
      "mimeapps.list".force = true; # overwrite the default file which keeps being recreated by Ubuntu
      "blesh/init.sh".text =
        ''
          ble-import integration/zoxide
          ble-import integration/nix-completion.bash
          ble-import vim-airline
          bleopt vim_airline_theme=raven
          bleopt vim_airline_section_c=
          bleopt vim_airline_section_b=
          bleopt vim_airline_section_x=
          bleopt vim_airline_section_y=
          # ctrl+c to discard line
          ble-bind -m vi_imap -f 'C-c' discard-line
          ble-bind -m vi_nmap -f 'C-c' discard-line
        '';
      "cspell/cspell.json".text =
        ''
          {
            "import": [
              "${pkgs.cspell-dict-pt-br}/share/cspell-dict-pt-br/cspell-ext.json"
            ]
          }
        '';
      "systemd/user/onedriver@.service" = {
        enable = !setup.wsl;
        source = "${pkgs.onedriver}/share/systemd/user/onedriver@.service";
      };
    };
    dataFile = { };
    desktopEntries = if setup.wsl then { } else {
      ulauncher = {
        type = "Application";
        name = "Ulauncher";
        comment = "Application launcher for Linux";
        icon = "ulauncher";
        genericName = "Launcher";
        categories = [ "GNOME" "GTK" "Utility" ];
        terminal = false;
        exec = "env GDK_BACKEND=x11 ulauncher --hide-window";
        settings = {
          SingleMainWindow = "true";
          TryExec = "ulauncher";
          X-GNOME-UsesNotifications = "true";
        };
      };
    };
    mimeApps = {
      enable = true;
      associations = {
        added =
          if setup.wsl then { } else {
            "x-scheme-handler/sms" = "org.gnome.Shell.Extensions.GSConnect.desktop";
            "x-scheme-handler/tel" = "org.gnome.Shell.Extensions.GSConnect.desktop";
          };
      };
      defaultApplications =
        if setup.wsl then {
          # browser:
          "text/html" = [ "wslview.desktop" ];
          "x-scheme-handler/http" = [ "wslview.desktop" ];
          "x-scheme-handler/https" = [ "wslview.desktop" ];
          "x-scheme-handler/about" = [ "wslview.desktop" ];
          "x-scheme-handler/unknown" = [ "wslview.desktop" ];
          "application/pdf" = [ "wslview.desktop" ];
          "x-scheme-handler/mailto" = [ "wslview.desktop" ];
          "application/xhtml+xml" = [ "wslview.desktop" ];
        } else {
          # onlyoffice:
          "application/vnd.oasis.opendocument.text" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.text-template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.text-web" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.text-master" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.writer" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.writer.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.writer.global" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-word" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/x-doc" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/rtf" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/rtf" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.wordperfect" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/wordperfect" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-word.document.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-word.template.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.spreadsheet-template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.calc" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.calc.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/msexcel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-excel.sheet.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-excel.template.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-excel.sheet.binary.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/csv" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/csv" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/excel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/x-excel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/x-msexcel" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/x-ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/comma-separated-values" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/tab-separated-values" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/x-comma-separated-values" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/x-csv" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.oasis.opendocument.presentation-template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.impress" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.sun.xml.impress.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/mspowerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-powerpoint.presentation.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.template" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-powerpoint.template.macroenabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.slide" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = [ "onlyoffice-desktopeditors.desktop" ];
          "application/vnd.ms-powerpoint.slideshow.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
          "x-scheme-handler/oo-office" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/docxf" = [ "onlyoffice-desktopeditors.desktop" ];
          "text/oform;" = [ "onlyoffice-desktopeditors.desktop" ];
          # browser:
          "text/html" = [ "librewolf.desktop" ];
          "x-scheme-handler/http" = [ "librewolf.desktop" ];
          "x-scheme-handler/https" = [ "librewolf.desktop" ];
          "x-scheme-handler/about" = [ "librewolf.desktop" ];
          "x-scheme-handler/unknown" = [ "librewolf.desktop" ];
          "application/pdf" = [ "librewolf.desktop" ];
          "x-scheme-handler/mailto" = [ "librewolf.desktop" ];
          "application/xhtml+xml" = [ "librewolf.desktop" ];
          # telegram:
          "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
        };
    };
  };

  services = {
    gpg-agent = {
      enable = !setup.wsl;
      enableExtraSocket = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 34560000; # 400 days
      defaultCacheTtlSsh = 34560000;
      maxCacheTtl = 34560000;
      maxCacheTtlSsh = 34560000;
      extraConfig =
        ''
          pinentry-timeout 34560000
        '';
    };

    keybase.enable = !setup.wsl;

    kbfs.enable = !setup.wsl;

    syncthing = {
      enable = false; # !setup.wsl; # todo: not using it for now. remove?
      overrideDevices = false;
      overrideFolders = false;
      tray = {
        enable = false; # !setup.wsl; # todo: not using it for now. remove?
      };
    };

    ollama = {
      # Get up and running with large language models locally, using ROCm for AMD GPU acceleration https://ollama.com/
      enable = !setup.wsl;
      package = pkgs.ollama-rocm;
      # acceleration= "rocm"; # checking from nixpkgs.config.rocmSupport
    };

    activitywatch = {
      # Best free and open-source automated time tracker https://activitywatch.net/
      enable = !setup.wsl;
      settings = {
        custom_static = {
          aw-watcher-media-player = "${pkgs.aw-watcher-media-player}/share/aw-watcher-media-player/visualization";
        };
      };
      watchers = {
        awatcher = {
          package = pkgs.awatcher;
        };
        aw-watcher-media-player = {
          package = pkgs.aw-watcher-media-player;
        };
      };
    };

  };

  systemd = import ./systemd.nix { inherit setup; inherit pkgs; };
}
