{ config, pkgs, lib, inputs, setup, ... }:

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
    packages =
      let
        nixGLwrap = pkg: if setup.isNixOS then pkg else config.lib.nixGL.wrap pkg;
        basic_pkgs = (with pkgs; [
          # common basic packages
          bash
          bash-completion
          extra-completions
          (callPackage ./cheats/default.nix { })
          dotnet-install
          dotnet-sdk
          dotnet-tools
          terraform
          vault
          psmisc
          coreutils-full
          util-linux
          libnotify
          powershell
          curl
          wget
          file
          gnupg
          pinentry-gnome3
          vim_configurable
          htop
          gitFull
          nix-index
          xdg-utils
          nil
          nixpkgs-fmt
          bat
          iperf
          inetutils
          jq
          mosh
          powerline
          socat
          tmux
          tree
          httpie
          glibcLocales
          gnumake
          nettools
          eza
          delta
          carapace
          fzf
          zoxide
          navi
          ruby_3_2
          fenix.complete.toolchain # or fenix.stable.defaultToolchain, or beta. Rust toolchains.
          cargo-completions
          yq-go
          tzdata
          unzip
          zip
          docker-client
          docker-compose
          dust
          fd
          just
          procs
          tealdeer
          githooks
          ranger
          colorized-logs
          zellij
          hub
          trash-cli
          nodePackages_latest.nodejs
          nodePackages.yarn
          loadtest
          prettier-plugin-awk
          node2nix
          nodePackages.prettier
          nodePackages.eslint
          nodePackages.bash-language-server
          (bats.withLibraries (p: [ p.bats-support p.bats-assert ]))
          git-ignore
          http-server
          cachix # install cache, for example, with: $HOME/.nix-profile/bin/cachix use nix-community
          (nixGLwrap kitty)
          dhcping
          ipcalc
          arp-scan
        ] ++ (if setup.wsl then [
          # wsl basic packages
          wslu
        ] else [
          # non wsl basic packages
          android-tools
          (nixGLwrap bitwarden-desktop)
          blanket
          eartag
          eyedropper
          (nixGLwrap firefox)
          forge-sparks
          gnome-contacts
          polari
          gnome-podcasts
          gnome-solanum
          gnome-tweaks
          gnome-extension-manager
          hwloc
          keybase-gui
          newsflash
          (nixGLwrap obsidian)
          (nixGLwrap onlyoffice-bin)
          (nixGLwrap openrgb-with-all-plugins)
          (nixGLwrap pinta)
          (nixGLwrap remmina)
          shortwave
          switcheroo
          (nixGLwrap telegram-desktop)
          textpieces
          (nixGLwrap vlc)
          (nixGLwrap warp)
          (nixGLwrap youtube-music)
          xclip
          nerd-fonts.caskaydia-cove
          nerd-fonts.symbols-only
        ] ++ (with gnomeExtensions; [
          # gsconnect # todo: not running, see: https://github.com/NixOS/nixpkgs/issues/173301
          blur-my-shell
          burn-my-windows
          caffeine
          clipboard-history
          compiz-alike-magic-lamp-effect
          compiz-windows-effect
          desktop-cube # not enabled
          fly-pie
          freon
          hibernate-status-button
          workspace-matrix
        ])
        ) ++ (if setup.isNixOS then [
          # NixOS basic packages
        ] else [
          # non NixOS basic packages
          pkgs.nixgl.nixGLIntel
        ]));
        non_basic_pkgs = lib.lists.optionals (!setup.basicSetup) (with pkgs; [
          # common non basic packages
          ookla-speedtest
          slides
          mermaid-cli
          presenterm
          hugo
          (nixGLwrap element-desktop)
          ccd2iso
          iat
          apparmor-utils
          chart-releaser
          docker-show-context
          deno
          opentofu
          krew
          ctop
          go
          gcc
          docker-slim
          asciinema
          bison
          cowsay
          figlet
          fontforge
          ghostscript
          gzip
          inotify-tools
          neovim
          nmap
          pandoc
          ripgrep
          screenfetch
          shellcheck
          silver-searcher
          w3m
          (nixGLwrap chromium)
          temurin-bin-23
          maven
          (azure-cli.withExtensions [ azure-cli.extensions.containerapp ])
          kubectl
          kubespy
          dive
          kubernetes-helm
          istioctl
          tflint
          gh
          gh-copilot
          k9s
          awscli2
          k3d
          act
          kn
          func
          kubecolor
          k6
          xlsx2csv
          clolcat
          bandwhich
          cargo-update
          cargo-edit
          cargo-expand
          cargo-outdated
          cargo-watch
          cargo-cross
          cargo-binstall
          gping
          grex
          sccache
          tokei
          gox
          manifest-tool
          shfmt
          neofetch
          imagemagick
          git-lfs
          kubectx
          lazydocker
          mqttx
        ] ++ (if setup.wsl then [
          # wsl non basic packages
        ] else [
          # non wsl non basic packages
          dconf2nix
          (nixGLwrap whatsapp-for-linux)
          slack
          discord
          (nixGLwrap obs-studio)
          (nixGLwrap kdePackages.kdenlive)
          (nixGLwrap glaxnimate)
          (nixGLwrap openshot-qt)
          (nixGLwrap wireshark)
          (nixGLwrap brave)
          (nixGLwrap orca-slicer)
          (nixGLwrap fritzing)
        ]) ++ (if setup.isNixOS then [
          # NixOS non basic packages
          vscode-fhs
          microsoft-edge
          # protonup-qt # to use with steam
        ] else
          (if setup.wsl then [
            # non NixOS wsl non basic packages
          ] else [
            # non NixOS non wsl non basic packages
            (nixGLwrap vscode)
          ])
        ));
        all_packages = basic_pkgs ++ non_basic_pkgs;
      in
      all_packages;

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
          export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
          eval "`zoxide init bash`"
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
          [ "# Shell session variables:" ]
          (lib.mapAttrsToList (k: v: "export ${k}=${v}") shellSessionVariables)
          [ "# Bash session variables:" ]
          (lib.mapAttrsToList (k: v: "export ${k}=${v}") bashSessionVariables)
          [
            ''
              # beginning of .bashrc
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

    starship = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = false;
    };

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
      enableBashIntegration = true;
      enableNushellIntegration = true;
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
      enableBashIntegration = true;
      enableNushellIntegration = true;
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
  };

  systemd = {
    user = {
      settings = {
        Manager = {
          ManagerEnvironment = {
            XDG_DATA_DIRS = "%u/.local/share:%u/.local/share/flatpak/exports/share:%u/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share/:/usr/share/:/usr/share/gnome:/usr/share/ubuntu:/var/lib/flatpak/exports/share:/var/lib/snapd/desktop";
            PATH = "/bin:%u/.local/bin:%u/.local/share/npm/bin:%u/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/sbin:/snap/bin:/usr/bin:/usr/games:/usr/local/bin:/usr/local/games:/usr/local/sbin:/usr/sbin";
          };
          DefaultEnvironment = {
            XDG_DATA_DIRS = "%u/.local/share:%u/.local/share/flatpak/exports/share:%u/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share/:/usr/share/:/usr/share/gnome:/usr/share/ubuntu:/var/lib/flatpak/exports/share:/var/lib/snapd/desktop";
            PATH = "/bin:%u/.local/bin:%u/.local/share/npm/bin:%u/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/sbin:/snap/bin:/usr/bin:/usr/games:/usr/local/bin:/usr/local/games:/usr/local/sbin:/usr/sbin";
          };
        };
      };
      startServices = "sd-switch";
      targets =
        let
          commonTargets = { };
          otherTargets =
            if !setup.wsl then
              { } else {
              wsl-forward-gpg-all = {
                Unit = {
                  Description = "Forward gpg, gpg-extra and ssh to Windows";
                  Wants = [
                    "wsl-forward-gpg.socket"
                    "wsl-forward-gpg-extra.socket"
                    "wsl-forward-ssh.socket"
                  ];
                };
                Install = {
                  WantedBy = [ "default.target" ];
                };
              };
            };
        in
        commonTargets // otherTargets;
      services =
        let
          commonServices = { };
          otherServices =
            if !setup.wsl then
              {
                mount-data = {
                  Unit = { Description = "Mount private and ecrypted directory"; };
                  Service = {
                    ExecStart = [ ./systemd/mount-data ];
                    StandardOutput = "journal";
                    Type = "simple";
                  };
                  Install = {
                    WantedBy = [ "default.target" ];
                  };
                };
              } else {
              # todo: remove. Necessary to run some wayland apps in WSL until https://github.com/microsoft/wslg/issues/1156#issuecomment-2094572691 gets fixed
              wsl-symlink-wayland = {
                Unit = { Description = "Symlink WSL wayland socket"; };
                Service = {
                  ExecStart = [
                    "ln -s /mnt/wslg/runtime-dir/wayland-0 %t/wayland-0"
                    "ln -s /mnt/wslg/runtime-dir/wayland-0.lock %t/wayland-0.lock"
                  ];
                  ExecStartPre = [
                    "rm -f %t/wayland-0 %t/wayland-0.lock"
                  ];
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = [ "default.target" ];
                };
              };
              "wsl-forward-gpg-extra@" = {
                Unit = {
                  Description = "Forward gpg extra to Windows";
                  Requires = "wsl-forward-gpg-extra.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --gpg-extra --instance %i";
                };
              };
              "wsl-forward-gpg@" = {
                Unit = {
                  Description = "Forward gpg to Windows";
                  Requires = "wsl-forward-gpg.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --gpg --instance %i";
                };
              };
              "wsl-forward-ssh@" = {
                Unit = {
                  Description = "Forward ssh to Windows";
                  Requires = "wsl-forward-ssh.socket";
                  After = "network-online.target";
                  Wants = "network-online.target";
                };
                Service = {
                  ExecStart = "${./systemd/wsl-forward-gpg} --ssh --instance %i";
                };
              };
            };
        in
        commonServices // otherServices;
      sockets =
        let
          commonSockets = { };
          otherSockets =
            if !setup.wsl then
              { } else {
              wsl-forward-gpg-extra = {
                Unit = {
                  Description = "Forward gpg extra socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/S.gpg-agent.extra";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };
              };
              wsl-forward-gpg = {
                Unit = {
                  Description = "Forward gpg socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/S.gpg-agent";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };
              };
              wsl-forward-ssh = {
                Unit = {
                  Description = "Forward ssh socket to Windows";
                  PartOf = "wsl-forward-gpg-all.target";
                };
                Socket = {
                  # %t is XDG_RUNTIME_DIR
                  ListenStream = "%t/gnupg/ssh.sock";
                  SocketMode = "0600";
                  DirectoryMode = "0700";
                  Accept = "yes";
                };
                Install = {
                  WantedBy = [ "sockets.target" ];
                };

              };
            };
        in
        commonSockets // otherSockets;
    };
  };
}
