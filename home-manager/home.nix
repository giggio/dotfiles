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
  nixGLwrap = pkg: if setup.isNixOS then pkg else config.lib.nixGL.wrap pkg;
in
rec {
  imports = (if setup.wsl then [
  ] else [
    ./dconf/dconf.nix
    ./virtualbox.nix
  ]);

  nixGL = {
    packages = inputs.nixGL.packages;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
  };

  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.strings.getName pkg) [
        "code"
        "discord"
        "gh-copilot"
        "microsoft-edge-stable"
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
      inputs.nixGL.overlay
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
    stateVersion = "24.11"; # Check if there are state version changes before changing this fiels: https://nix-community.github.io/home-manager/release-notes.xhtml
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
      EDITOR = "vim";
      XDG_DATA_HOME = "\${XDG_DATA_HOME:-$HOME/.local/share}";
      XDG_STATE_HOME = "\${XDG_STATE_HOME:-$HOME/.local/state}";
      XDG_CACHE_HOME = "\${XDG_CACHE_HOME:-$HOME/.cache}";
      NPM_CONFIG_PREFIX = "\${NPM_CONFIG_PREFIX:-$HOME/.local/share/npm}";
      BASIC_SETUP = "\${BASIC_SETUP:-false}";
    };

    file = {
      ".cargo/.keep".text = "";
      ".local/bin/dotnet-uninstall".source = ./bin/dotnet-uninstall;
      ".local/bin/hm".source = ./bin/hm;
      ".hushlogin".text = "";
      ".XCompose".text =
        ''
          <dead_acute> <C> : "Ç" Ccedilla # LATIN CAPITAL LETTER C WITH CEDILLA
          <dead_acute> <c> : "ç" ccedilla # LATIN SMALL LETTER C WITH CEDILLA
        '';
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
      ".inputrc".text = "set bell-style none";
      ".vimrc".text = "source ~/.vim/.vimrc";
    };

  };

  programs = {
    home-manager = {
      # Let Home Manager install and manage itself.
      enable = true;
    };

    bash = {
      enable = true;
      initExtra =
        ''
          # end of nix configuration

          # ending of .bashrc:
          if [ -f "$HOME"/.cargo/env ]; then
            source "$HOME/.cargo/env"
          fi
          if [[ $TERM != "dumb" ]]; then
            eval "$(starship init bash)"
          fi
          if [[ $TERM == "xterm-kitty" ]]; then
            # Setting kitty shell integration manually to avoid adding the _ksi script to PROMPT_COMMAND
            # this happens if there is a running program when we create a new tab,
            # but only if we use `history -a` in the PROMPT_COMMAND, we want to do.
            # See: https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
            if [ -v KITTY_INSTALLATION_DIR ]; then
              if [[ "$PROMPT_COMMAND" != *'_ksi_'* ]]; then
                export KITTY_SHELL_INTEGRATION="no-cursor"
                # shellcheck disable=SC1091
                source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
              fi
            fi
          fi
          if [[ "$PROMPT_COMMAND" != *'history -a'* ]]; then
            export PROMPT_COMMAND=''${PROMPT_COMMAND:+"$PROMPT_COMMAND;"}"history -a"
          fi
          export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
          if [ -d "$HOME/.kube" ]; then
            KUBECONFIG=`find "$HOME"/.kube -maxdepth 1 -type f ! -name '*.bak' ! -name '*.backup' ! -name kubectx | sort | paste -sd ":" -`
            export KUBECONFIG
          fi
          source ${pkgs.fzf}/share/fzf/key-bindings.bash
          source ${pkgs.fzf}/share/fzf/completion.bash
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

          source "$(blesh-share)/ble.sh"
          # end of .bashrc

          # beginning of configurations coming from other options, like gpg-agent, direnv and zoxide
        '';
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
            "??" = "gh-copilot suggest -t shell";
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
            git = "hub";
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
              source ${pkgs.kubectl-aliases}/bin/kubecolor_aliases.bash
              source ${pkgs.complete-alias}/bin/complete_alias
              source "$HOME/.dotfiles/bashscripts/.bashrc"
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

    ghostty = {
      enable = true;
      package = (nixGLwrap pkgs.ghostty);
      installVimSyntax = true;
      settings = {
        theme = "Ubuntu";
        font-family = "CaskaydiaCove Nerd Font Mono";
        font-size = 14;
        window-decoration = false;
      };
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
        source = "${pkgs.kitty}/share/applications/kitty.desktop";
      };
      "autostart/forge-sparks.desktop".text =
        ''
          [Desktop Entry]
          Name=Forge Sparks
          Exec=forge-sparks --hidden
          Type=Application
          StartupNotify=true
          Terminal=false
          Icon=com.mardojai.ForgeSparks
        '';
      "burn-my-windows/profiles/close.conf".source = ./dconf/cfg/burn-close.conf;
      "burn-my-windows/profiles/close-edge.conf".source = ./dconf/cfg/burn-app-edge.conf;
      "burn-my-windows/profiles/open.conf".source = ./dconf/cfg/burn-open.conf;
      "alacritty".source = ./config/alacritty;
      "navi/config.yaml".source = ./config/navi-config.yaml;
      "terminator/config".source = ./config/terminator-config;
      "starship.toml".source = ./config/starship.toml;
      "git/attributes".source = ./config/git-attributes;
      "carapace/bridges.yaml".source = ./config/carapace/bridges.yaml;
      "carapace/overlays".source = ./config/carapace/overlays;
      "carapace/specs".source = ./config/carapace/specs;
      "mimeapps.list".force = true; # overwrite the default file which keeps being recreated by Ubuntu
      "blesh/init.sh".text =
        ''
          ble-import integration/fzf-completion
          ble-import integration/fzf-key-bindings
          ble-import integration/zoxide
          ble-import integration/nix-completion.bash
          ble-import vim-airline
          bleopt vim_airline_theme=minimalist
          # ctrl+c to discard line
          ble-bind -m vi_imap -f 'C-c' discard-line
          ble-bind -m vi_nmap -f 'C-c' discard-line
        '';
    };
    dataFile = { };
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
          "text/html" = [ "brave-browser.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
          "x-scheme-handler/about" = [ "brave-browser.desktop" ];
          "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
          "application/pdf" = [ "brave-browser.desktop" ];
          "x-scheme-handler/mailto" = [ "brave-browser.desktop" ];
          "application/xhtml+xml" = [ "brave-browser.desktop" ];
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
      pinentryPackage = pkgs.pinentry-gnome3;
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
      enable = !setup.wsl;
      overrideDevices = false;
      overrideFolders = false;
      tray = {
        enable = !setup.wsl;
      };
    };

  };

  systemd = import ./systemd.nix { inherit setup; };
}
