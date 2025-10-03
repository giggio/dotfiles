{ config, pkgs, pkgs-stable, lib, setup, ... }:

let
  nixGLwrap = pkg: if setup.isNixOS then pkg else config.lib.nixGL.wrap pkg;
  basic_pkgs = (with pkgs; ([
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
    vim-full
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
    glibcLocales
    gnumake
    nettools
    eza
    delta
    carapace
    fzf
    zoxide
    navi
    bundix
    (ruby_3_4.withPackages (ps: with ps; [ ]))
    my_gems # bundling ruby-lsp and other gems (in the future)
    fenix.stable.toolchain # or fenix.complete.defaultToolchain, or beta. Rust toolchains.
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
    procs # A modern replacement for ps written in Rust https://github.com/dalance/procs
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
    ipcalc # Simple IP network calculator (CIDR) https://gitlab.com/ipcalc/ipcalc
    arp-scan
    xh # httpie
    dua # disk usage analyzer
    yazi # Blazing Fast Terminal File Manager
    kondo # A command-line tool to clean up your code
    universal-ctags # Maintained ctags implementation https://ctags.io/
    nixd # Nix language server https://github.com/nix-community/nixd/tree/main
    dockerfile-language-server-nodejs # A language server for Dockerfiles powered by Node.js https://github.com/rcjsuen/dockerfile-language-server
    docker-compose-language-service # Language service for Docker Compose documents https://github.com/microsoft/compose-language-service
    systemd-language-server # Systemd language server https://github.com/psacawa/systemd-language-server
    omnisharp-roslyn # C# language server https://github.com/OmniSharp/omnisharp-roslyn
    csharp-ls # C# language server https://github.com/razzmatazz/csharp-language-server
    lldb_20 # for lldb-dab, the debugger adapter protocol server for lldb, used in Rust
    code-lldb # my custom package that extracts the binary
    vscode-js-debug # A DAP-compatible JavaScript debugger https://github.com/microsoft/vscode-js-debug
    typescript-language-server # TypeScript & JavaScript Language Server https://github.com/typescript-language-server/typescript-language-server
    tree-sitter # An incremental parsing system for programming tools https://github.com/tree-sitter/tree-sitter
    marksman # Write Markdown with code assist and intelligence in the comfort of your favourite editor https://github.com/artempyanykh/marksman/
    markdownlint-cli2 # Fast, flexible, configuration-based command-line interface for linting Markdown/CommonMark files with the markdownlint library https://github.com/DavidAnson/markdownlint-cli2
    neovim
    (lua5_1.withPackages (ps: [
      # High-performance JIT compiler for Lua 5.1 https://luajit.org/
      ps.luarocks # A package manager for Lua modules https://luarocks.org/
      ps.tiktoken_core # An experimental port of OpenAI's Tokenizer to lua # used for Github Copilot chat nvim plugin # https://github.com/gptlang/lua-tiktoken
      # luacheck # A static analyzer and a linter for Lua
      ps.inspect # Human-readable representation of Lua tables https://github.com/kikito/inspect.lua
    ]))
    emmet-language-server # Language server for emmet.io (Based on VSCode emmet ls) https://github.com/olrtg/emmet-language-server
    vscode-langservers-extracted # vscode-langservers bin collection https://github.com/hrsh7th/vscode-langservers-extracted
    # todo: revisit cspell-lsp when https://github.com/vlabo/cspell-lsp/issues/13 is fixed
    # cspell-lsp # A simple source code spell checker for helix (and NeoVim) https://github.com/vlabo/cspell-lsp
    pv # Tool for monitoring the progress of data through a pipeline https://www.ivarch.com/programs/pv.shtml
    sqls # SQL language server written in Go https://github.com/sqls-server/sqls
    gopls # Official language server for the Go language https://github.com/golang/tools/tree/master/gopls
    bash-language-server # A language server for Bash https://github.com/bash-lsp/bash-language-server
    systemd-language-server # Language Server for Systemd unit files https://github.com/psacawa/systemd-language-server
    yaml-language-server # Language Server for YAML Files https://github.com/redhat-developer/yaml-language-server
    dockerfile-language-server-nodejs # Language server for Dockerfiles powered by Node.js, TypeScript, and VSCode technologies https://github.com/rcjsuen/dockerfile-language-server
    # roslyn-ls # Language server behind C# Dev Kit for Visual Studio Code https://github.com/dotnet/vscode-csharp # todo: broken, waiting for https://github.com/NixOS/nixpkgs/pull/439459 to reach unstable
    fsautocomplete # FsAutoComplete project (FSAC) provides a backend service for rich editing or intellisense features for editors https://github.com/fsharp/FsAutoComplete
    basedpyright # Type checker for the Python language (and lsp) https://github.com/detachhead/basedpyright
    uv # Extremely fast Python package installer and resolver, written in Rust https://docs.astral.sh/uv/
    powershell-editor-services # Common platform for PowerShell development support in any editor or application https://github.com/PowerShell/PowerShellEditorServices
  ]) ++ (with llvmPackages_20; [
    clang-tools # Standalone command line tools for C++ development https://clangd.llvm.org/
    clangUseLLVM # C language family frontend for LLVM (wrapper script) https://clang.llvm.org/
    clang-manpages # man page for Clang
    vim-language-server # VImScript language server, LSP for vim script https://github.com/iamcco/vim-language-server
    lua-language-server # Lua language server https://github.com/LuaLS/lua-language-server
    cspellls # Custom cspell language server made from the vscode extension
    hadolint # Dockerfile linter, validate inline bash https://github.com/hadolint/hadolint
    # end of common basic packages
  ]) ++ (if setup.wsl then [
    # wsl basic packages
    wslu
    # end of wsl basic packages
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
    smile
    ulauncher # Feature rich application Launcher for Linux https://github.com/Ulauncher/Ulauncher/
  ] ++ (with gnomeExtensions; [
    # gsconnect # todo: not running, see: https://github.com/NixOS/nixpkgs/issues/173301
    (gnome46Extensions.${blur-my-shell.extensionUuid})
    (gnome46Extensions.${burn-my-windows.extensionUuid})
    (gnome46Extensions.${caffeine.extensionUuid})
    (gnome46Extensions.${clipboard-history.extensionUuid})
    (gnome46Extensions.${compiz-alike-magic-lamp-effect.extensionUuid})
    (gnome46Extensions.${compiz-windows-effect.extensionUuid})
    (gnome46Extensions.${desktop-cube.extensionUuid}) # not enabled
    (gnome46Extensions.${fly-pie.extensionUuid})
    (gnome46Extensions.${freon.extensionUuid})
    (gnome46Extensions.${hibernate-status-button.extensionUuid})
    (gnome46Extensions.${workspace-matrix.extensionUuid})
    (gnome46Extensions.${smart-auto-move.extensionUuid})
    (gnome46Extensions.${smile-complementary-extension.extensionUuid})
  ])
    # end of non wsl basic packages
  ) ++ (if setup.isNixOS then [
    # NixOS basic packages
    # end of NixOS basic packages
  ] else [
    # non NixOS basic packages
    pkgs.nixgl.nixGLIntel
    # end of non NixOS basic packages
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
    (hiPrio gcc)
    docker-slim
    asciinema
    bison
    cowsay
    figlet
    fontforge
    ghostscript
    gzip
    inotify-tools
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
    bacon # Rust background code checker
    cargo-info # Cargo subcommand to show crates info from crates.io
    rusty-man # Command-line viewer for documentation generated by rustdoc
    wiki-tui # Simple and easy to use Wikipedia Text User Interface
    lynx # text web browser https://lynx.invisible-island.net/
    fdupes # program for identifying or deleting duplicate files residing within specified directories https://github.com/adrianlopezroche/fdupes
    wezterm # GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust
    sqlite # Self-contained, serverless, zero-configuration, transactional SQL database engine https://www.sqlite.org/
    ladybird # a truly independent web browser https://ladybird.org/
    # end of common non basic packages
  ] ++ (if setup.wsl then [
    # wsl non basic packages
    # end of wsl non basic packages
  ] else [
    # non wsl non basic packages
    dconf2nix
    # (nixGLwrap wasistlos) # ex whatsapp-for-linux, not working correctly, using snap for now
    slack
    discord
    (nixGLwrap obs-studio)
    (nixGLwrap kdePackages.kdenlive)
    (nixGLwrap glaxnimate)
    # (nixGLwrap openshot-qt) # Free, open-source video editor http://openshot.org/ # todo: depending on qtwebengine, which is insecure, try to add it back later
    (nixGLwrap wireshark)
    (nixGLwrap brave)
    # (nixGLwrap librewolf-bin) # review if librewolf is better sometime in the future https://bsky.app/profile/giggio.net/post/3li63msr5r226
    (nixGLwrap firefox)
    (nixGLwrap orca-slicer)
    (nixGLwrap fritzing)
    mqttx
    mqtt-explorer
    kdePackages.k3b # Full-featured CD/DVD/Blu-ray burning and ripping application
    cdrtools # Highly portable CD/DVD/BluRay command line recording software
    doublecmd # Two-panel graphical file manager written in Pascal https://github.com/doublecmd/doublecmd
    tor-browser # Privacy-focused browser routing traffic through the Tor network https://www.torproject.org/
    # end of non wsl non basic packages
  ]) ++ (if setup.isNixOS then [
    # NixOS non basic packages
    vscode-fhs
    microsoft-edge
    # protonup-qt # to use with steam
    # end of NixOS non basic packages
  ] else
    (if setup.wsl then [
      # non NixOS wsl non basic packages
      # end of non NixOS wsl non basic packages
    ] else [
      # non NixOS non wsl non basic packages
      (nixGLwrap vscode)
      # end of non NixOS non wsl non basic packages
    ])
  ));
  stable_basic_pkgs = (with pkgs-stable; [
    # common basic packages (stable)
    # end of common basic packages (stable)
  ] ++ (if setup.wsl then [
    # wsl basic packages (stable)
    # enf of wsl basic packages (stable)
  ] else [
    # non wsl basic packages (stable)
    # end of non wsl basic packages (stable)
  ]) ++ (if setup.isNixOS then [
    # NixOS basic packages (stable)
    # end of NixOS basic packages (stable)
  ] else [
    # non NixOS basic packages (stable)
    # end of non NixOS basic packages (stable)
  ]));
  stable_non_basic_pkgs = lib.lists.optionals (!setup.basicSetup) (with pkgs-stable; [
    # common non basic packages (stable)
    # end of common non basic packages (stable)
  ] ++ (if setup.wsl then [
    # wsl non basic packages (stable)
    # end of wsl non basic packages (stable)
  ] else [
    # non wsl non basic packages (stable)
    # end of non wsl non basic packages (stable)
  ]) ++ (if setup.isNixOS then [
    # NixOS non basic packages (stable)
    # enf of NixOS non basic packages (stable)
  ] else
    (if setup.wsl then [
      # non NixOS wsl non basic packages (stable)
      # end of non NixOS wsl non basic packages (stable)
    ] else [
      # non NixOS non wsl non basic packages (stable)
      # end of non NixOS non wsl non basic packages (stable)
    ])
  ));
  all_packages = basic_pkgs ++ non_basic_pkgs ++ stable_basic_pkgs ++ stable_non_basic_pkgs;
in
all_packages
