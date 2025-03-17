{ config, pkgs, pkgs-stable, lib, setup, ... }:

let
  nixGLwrap = pkg: if setup.isNixOS then pkg else config.lib.nixGL.wrap pkg;
  basic_pkgs = (with pkgs; [
    # common basic packages
    bash
    bash-completion
    extra-completions
    (callPackage ./cheats/default.nix { })
    starship
    (blesh.overrideAttrs {
      version = "nightly-20250209+4338bbf";
      src = fetchzip {
        url = "https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly-20250209+4338bbf.tar.xz";
        sha256 = "sha256-zkYAvxsmKb7Gb4qNQle4b/nS9VLwBBtHgINvIAKwWes=";
      };
    })
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
    smart-auto-move
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
    pagefind
    (nixGLwrap element-desktop)
    ccd2iso
    iat
    apparmor-utils
    chart-releaser
    docker-show-context
    deno
    opentofu
    krew
    kube-capacity # krew
    kail # krew
    ketall # krew
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
    kubectx
    lazydocker
    (nixGLwrap ghostty)
    fabric-ai
    nixpkgs-review
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
    # (nixGLwrap librewolf-bin) # review if librewolf is better sometime in the future https://bsky.app/profile/giggio.net/post/3li63msr5r226
    (nixGLwrap firefox)
    (nixGLwrap orca-slicer)
    (nixGLwrap fritzing)
    # mqttx # todo: move from unstable when fixed: https://github.com/NixOS/nixpkgs/issues/390537
    mqtt-explorer
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
  stable_basic_pkgs = (with pkgs-stable; [
    # common basic packages
  ] ++ (if setup.wsl then [
    # wsl basic packages
  ] else [
    # non wsl basic packages
  ]) ++ (if setup.isNixOS then [
    # NixOS basic packages
  ] else [
    # non NixOS basic packages
  ]));
  stable_non_basic_pkgs = lib.lists.optionals (!setup.basicSetup) (with pkgs-stable; [
    # common non basic packages
    mqttx # todo: move to unstable when fixed: https://github.com/NixOS/nixpkgs/issues/390537
  ] ++ (if setup.wsl then [
    # wsl non basic packages
  ] else [
    # non wsl non basic packages
  ]) ++ (if setup.isNixOS then [
    # NixOS non basic packages
  ] else
    (if setup.wsl then [
      # non NixOS wsl non basic packages
    ] else [
      # non NixOS non wsl non basic packages
    ])
  ));
  all_packages = basic_pkgs ++ non_basic_pkgs ++ stable_basic_pkgs ++ stable_non_basic_pkgs;
in
all_packages
