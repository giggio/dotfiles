{ config, pkgs, lib, inputs, ... }:

let
  basic_setup = (builtins.getEnv "BASIC_SETUP") == "true";
  wsl = (builtins.getEnv "WSL") == "true";
  githooks = inputs.githooks.packages."${pkgs.system}".default;
  nixGLIntel = inputs.nixGL.packages."${pkgs.system}".nixGLIntel;
in
rec {
  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.strings.getName pkg) [
        "obsidian"
      ];
      # allowUnfree = true;
    };
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
          rustup
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
          nushell
          procs
          tealdeer
          githooks
          ranger
          colorized-logs
          zellij
        ]);
        wsl_pkgs = if wsl then (with pkgs; [ wslu ]) else [ ];
        not_wsl_pkgs = if wsl then [] else
        (with pkgs; [
          android-tools
          bitwarden-desktop
          firefox
          hwloc
          (config.lib.nixGL.wrap kitty)
          nerdfonts
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
        extra_pkgs = if basic_setup then [ ] else
        (with pkgs; [
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
          hub
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
          (with dotnetCorePackages; combinePackages
            [
              sdk_6_0
              sdk_7_0
              sdk_8_0
            ])
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
          # cargo-update # todo: has a problem
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
        ]);
      in
      basic_pkgs ++ wsl_pkgs ++ not_wsl_pkgs ++ extra_pkgs;

    # Home Manager can also manage your environment variables through
    # 'sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    sessionVariables = {
      EDITOR = "vim";
      DOTNET_ROOT = "${(with pkgs.dotnetCorePackages; combinePackages
      [
        sdk_6_0
        sdk_7_0
        sdk_8_0
      ])}";
    };

    file =
      let
        sessionVariablesText = lib.concatStringsSep "\n" (lib.concatLists [
          [
            "std path add $\"($env.HOME)/.nix-profile/bin\" /nix/var/nix/profiles/default/bin"
          ]
          (lib.mapAttrsToList (k: v: "$env.${k} = ${v}") home.sessionVariables)
        ]
        );
      in
      {
        ".config/nushell/login.nu".text = sessionVariablesText;
      };

  };

  programs = {
    home-manager = {
      # Let Home Manager install and manage itself.
      enable = true;
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
  };

  fonts.fontconfig.enable = !wsl;

  xdg = {
    configFile = {
      "autostart/bitwarden.desktop".source = "${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop";
    };
    mimeApps = {
      enable = true;
      defaultApplications = if wsl then {
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
      enable = !wsl;
      enableExtraSocket = true;
      enableScDaemon = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  imports = [
    ./dconf/dconf.nix
    # todo: remove when https://github.com/nix-community/home-manager/pull/5355 gets merged:
    (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
      sha256 = "74f9fb98f22581eaca2e3c518a0a3d6198249fb1490ab4a08f33ec47827e85db";
    })
  ];

  nixGL.prefix = "${nixGLIntel}/bin/nixGLIntel";

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
