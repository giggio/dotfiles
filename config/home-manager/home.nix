{ config, pkgs, lib, inputs, ... }:

let
  basic_setup = (builtins.getEnv "BASIC_SETUP") == "true";
  wsl = (builtins.getEnv "WSL") == "true";
  githooks = inputs.githooks.packages."${pkgs.system}".default;
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
        ]);
        wsl_pkgs = if wsl then (with pkgs; [ wslu ]) else [ ];
        not_wsl_pkgs = if wsl then [] else
        (with pkgs; [
          android-tools
          bitwarden-desktop
          firefox
          hwloc
          nerdfonts
          obsidian
          pinta
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
  };

  fonts.fontconfig.enable = true;

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
