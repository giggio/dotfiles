{ config, pkgs, lib, inputs, pkgs-master,... }:

let
  githooks = inputs.githooks.packages."${pkgs.system}".default;
  nixGLIntel = inputs.nixGL.packages."${pkgs.system}".nixGLIntel;
  env = config.setup;
  # homeDir = "/home/${env.user}";
  dotnetCombinedPackages = (with pkgs.dotnetCorePackages; combinePackages
    [
      sdk_6_0
      sdk_7_0
      sdk_8_0
    ]);
  # todo: move shellSessionVariables somewhere else when https://github.com/nix-community/home-manager/issues/5474 is fixed
  # but, be careful, this is used by nushell and bash
  shellSessionVariables = {
    DOTNET_ROOT = "${dotnetCombinedPackages}";
  };
in
rec {
  imports = [
    ./setup.nix
    ~/.config/nix/.env.nix
    ./dconf/dconf.nix
    # todo: remove when https://github.com/nix-community/home-manager/pull/5355 gets merged:
    (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
      sha256 = "74f9fb98f22581eaca2e3c518a0a3d6198249fb1490ab4a08f33ec47827e85db";
    })
  ];

  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.strings.getName pkg) [
        "obsidian"
      ];
    };
    overlays = [
      inputs.fenix.overlays.default
    ];
  };

  home = {
    username = "giggio";
    homeDirectory = "/home/" + home.username;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.
    packages =
      let
        basic_pkgs = (with pkgs; [
          bash
          bash-completion
          (pkgs.callPackage ./completions.nix { inherit pkgs; })
          (pkgs.callPackage ./dotnet/dotnet-tools.nix { inherit pkgs; dotnet-sdk = dotnetCombinedPackages; })
          powershell
          curl
          wget
          file
          gnupg
          pinentry-gnome3
          vim_configurable
          htop
          git
          tmux
          starship
          nix-index
          xdg-utils
          nil
          nixpkgs-fmt
          bat
          pipx
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
          # rustup
          (fenix.stable.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          rust-analyzer-nightly
          yq-go
          tzdata
          unzip
          zip
          (python3.withPackages (python-pkgs: [
            python-pkgs.semver
          ]))
          docker-client
          docker-compose
          dust
          fd
          just
          # todo: change to nushell when the nixos-unstable branch gets updates from master.See https://status.nixos.org/
          pkgs-master.nushell
          procs
          tealdeer
          githooks
          ranger
          colorized-logs
          zellij
          hub
          nodePackages_latest.nodejs
          nodePackages.yarn
        ]);
        wsl_pkgs = lib.lists.optionals env.wsl (with pkgs; [ wslu ]);
        not_wsl_pkgs = lib.lists.optionals (!env.wsl)
        (with pkgs; [
          android-tools
          bitwarden-desktop
          firefox
          hwloc
          nixGLIntel
          obsidian
          onlyoffice-bin
          openrgb-with-all-plugins
          pinta
          remmina
          telegram-desktop
          vlc
          youtube-music
        ]);
        extra_pkgs = lib.lists.optionals (!env.basicSetup)
        (with pkgs; [
          (nerdfonts.override { fonts = [ "CascadiaCode" "NerdFontsSymbolsOnly" ]; })
          (config.lib.nixGL.wrap kitty)
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
          chromium
          dotnetCombinedPackages
          temurin-bin-21
          maven
          azure-cli
          kubectl
          kubespy
          dive
          kubernetes-helm
          istioctl
          tflint
          gh
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
          gping
          grex
          sccache
          tokei
          gox
          manifest-tool
          shfmt
          dconf2nix
          neofetch
          imagemagick
          git-lfs
          kubectx
        ]);
      in
      basic_pkgs ++ wsl_pkgs ++ not_wsl_pkgs ++ extra_pkgs;

    # Home Manager can also manage your environment variables through
    # 'sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    sessionPath = [
        "$HOME/bin"
        "$HOME/.local/bin"
        "$XDG_DATA_HOME/npm/bin"
    ];
    sessionVariables = {
      # this goes into ~/.nix-profile/etc/profile.d/hm-session-vars.sh, which is
      # loaded by .profile, and so only reloads if we logout and log back in
      EDITOR = "vim";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
      NPM_CONFIG_PREFIX = "$HOME/.local/share/npm";
    };

    file = {
      ".cargo/.keep".text = "";
      ".local/lib/systemd/wsl-forward-gpg" = {
        enable = env.wsl;
        source = ./systemd/wsl-forward-gpg;
      };
      ".local/bin/dotnet-uninstall".source =./bin/dotnet-uninstall;
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
      # shellcheck source=/dev/null
      source "$HOME/.local/lib/python3.10/site-packages/powerline/bindings/tmux/powerline.conf"
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
      ".npmrc".text = "sign-git-tag=true";
    };

  };

  programs = {
    home-manager = {
      # Let Home Manager install and manage itself.
      enable = true;
    };

    bash = {
      enable = true;
      initExtra = "# at the end of .bashrc";
      logoutExtra =
        ''
        # when leaving the console clear the screen to increase privacy
        if [ "$SHLVL" = 1 ]; then
          [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
        fi
        '';
      profileExtra =
        ''
        umask 022
        '';
      historySize = -1;
      historyFileSize = -1;
      historyFile = "$HOME/.bash_history2";
      sessionVariables = {
        # this goes to .profile, and only reloads if we logout and log back in
        # it should go to .bashrc, but it's not possible to set it there
        # see: https://github.com/nix-community/home-manager/issues/5474
        # move `shellSessionVariables` here this issue closes and this starts to go to .bashrc
        # but, carefully, `shellSessionVariables` is used by nushell and bash
      };
      shellAliases = {
        l = "ls -la";
      };
      shellOptions = [
        "histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"
      ];
      bashrcExtra = lib.concatStringsSep "\n" (lib.concatLists [
          [
            ''source "$HOME/.dotfiles/bashscripts/.bashrc"''
          ]
          (lib.mapAttrsToList (k: v: "${k}=${v}") shellSessionVariables)
        ]
        );
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

  fonts.fontconfig.enable = !env.wsl;

  xdg = {
    configFile = let
      sessionVariablesText = lib.concatStringsSep "\n" (lib.concatLists [
        [
          "# nushell"
        ]
        (lib.mapAttrsToList (k: v: "$env.${k} = ${v}") shellSessionVariables)
      ]
      );
    in
    {
      "nushell/login.nu".text = sessionVariablesText;
      "autostart/bitwarden.desktop" = {
        enable = !env.wsl;
        source = "${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop";
      };
      "alacritty".source = ./config/alacritty;
      "navi/config.yaml".source = ./config/navi-config.yaml;
      "terminator/config".source = ./config/terminator-config;
      "starship.toml".source = ./config/starship.toml;
    };
    mimeApps = {
      enable = true;
      defaultApplications = if env.wsl then {
        # browser:
        "text/html"=["wslview.desktop"];
        "x-scheme-handler/http"=["wslview.desktop"];
        "x-scheme-handler/https"=["wslview.desktop"];
        "x-scheme-handler/about"=["wslview.desktop"];
        "x-scheme-handler/unknown"=["wslview.desktop"];
        "application/pdf"=["wslview.desktop"];
        "x-scheme-handler/mailto"=["wslview.desktop"];
        "application/xhtml+xml"=["wslview.desktop"];
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
        "text/html"=["microsoft-edge.desktop"];
        "x-scheme-handler/http"=["microsoft-edge.desktop"];
        "x-scheme-handler/https"=["microsoft-edge.desktop"];
        "x-scheme-handler/about"=["microsoft-edge.desktop"];
        "x-scheme-handler/unknown"=["microsoft-edge.desktop"];
        "application/pdf"=["microsoft-edge.desktop"];
        "x-scheme-handler/mailto"=["microsoft-edge.desktop"];
        "application/xhtml+xml"=["microsoft-edge.desktop"];
        # telegram:
        "x-scheme-handler/tg"=["org.telegram.desktop.desktop"];
      };
    };
  };

  services = {
    gpg-agent = {
      enable = !env.wsl;
      enableExtraSocket = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  nixGL.prefix = "${nixGLIntel}/bin/nixGLIntel";

  systemd = {
    user = {
      startServices = "sd-switch";
      targets = let
        commonTargets = {};
        otherTargets = if !env.wsl then
        {
        } else {
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
      services = let
        commonServices = {};
        otherServices = if !env.wsl then
        {
        } else {
          # todo: remove. Necessary to run some wayland apps in WSL until https://github.com/microsoft/wslg/issues/1156#issuecomment-2094572691 gets fixed
          wsl-symlink-wayland = {
            Unit = { Description = "Symlink WSL wayland socket"; };
            Service = {
              ExecStart = [ "ln -s /mnt/wslg/runtime-dir/wayland-0 %t/wayland-0" "ln -s /mnt/wslg/runtime-dir/wayland-0.lock %t/wayland-0.lock" ];
              ExecStartPre = [ "rm -f %t/wayland-0 %t/wayland-0.lock" ];
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
              ExecStart = "%h/.local/lib/systemd/wsl-forward-gpg --gpg-extra --instance %i";
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
              ExecStart = "%h/.local/lib/systemd/wsl-forward-gpg --gpg --instance %i";
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
              ExecStart = "%h/.local/lib/systemd/wsl-forward-gpg --ssh --instance %i";
            };
          };
        };
      in
        commonServices // otherServices;
      sockets = let
        commonSockets = {};
        otherSockets = if !env.wsl then
        {
        } else {
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

  # systemd = {
  #   user = {
  #     services = {
  #       teste = {
  #         Unit = { Description = "Teste"; };
  #         Service = {
  #           ExecStart = "sleep infinity";
  #           Restart = "always";
  #         };
  #         Install = { WantedBy = [ "default.target" ]; };
  #       };
  #     };
  #   };
  # };
}
