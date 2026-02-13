{
  pkgs,
  # pkgs-stable,
  lib,
  setup,
  ...
}:

let
  basic_pkgs = (
    with pkgs;
    ([
      # common basic packages
      bash # GNU Bourne Again shell https://www.gnu.org/software/bash/
      bash-completion # Programmable completion for the bash shell https://github.com/scop/bash-completion
      extra-completions # More completions for bash and zsh
      (blesh.overrideAttrs {
        version = "nightly-20250209+4338bbf";
        src = fetchzip {
          url = "https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly-20250209+4338bbf.tar.xz";
          sha256 = "sha256-zkYAvxsmKb7Gb4qNQle4b/nS9VLwBBtHgINvIAKwWes=";
        };
      })
      terraform # Tool for building, changing, and versioning infrastructure https://www.terraform.io
      vault # Tool for managing secrets https://www.vaultproject.io
      psmisc # Small useful utilities that use the /proc filesystem https://gitlab.com/psmisc/psmisc
      coreutils-full # GNU Core Utilities https://www.gnu.org/software/coreutils/
      util-linux # System utilities for Linux https://github.com/util-linux/util-linux
      libnotify # Library for sending desktop notifications https://gitlab.gnome.org/GNOME/libnotify
      powershell # Cross-platform automation and configuration tool/framework https://github.com/PowerShell/PowerShell
      curl # Command line tool for transferring files with URL syntax https://curl.se/
      wget # Tool for retrieving files using HTTP, HTTPS, FTP and FTPS https://www.gnu.org/software/wget/
      file # Program that shows the type of files https://darwinsys.com/file/
      gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation https://gnupg.org/
      pinentry-gnome3 # GnuPG's interface to passphrase input https://gnupg.org/
      vim-full # Most popular clone of the VI editor https://www.vim.org/
      htop # Interactive process viewer https://htop.dev/
      gitFull # Distributed version control system https://git-scm.com/
      nix-index # Files database for nixpkgs https://github.com/nix-community/nix-index
      xdg-utils # Set of command line tools that assist applications with desktop integration tasks https://www.freedesktop.org/wiki/Software/xdg-utils/
      nil # Language server for Nix https://github.com/oxalica/nil
      nixpkgs-fmt # Nix code formatter for nixpkgs https://github.com/nix-community/nixpkgs-fmt
      nixfmt # The official formatter for Nix code https://github.com/NixOS/nixfmt
      iperf # Tool to measure IP bandwidth using UDP or TCP https://sourceforge.net/projects/iperf2/
      inetutils # Collection of common network programs https://www.gnu.org/software/inetutils/
      jq # Lightweight and flexible command-line JSON processor https://jqlang.github.io/jq/
      mosh # Mobile shell, allows roaming and intelligent local echo https://mosh.org/
      powerline # Ultimate statusline/prompt utility https://github.com/powerline/powerline
      socat # Utility for bidirectional data transfer between two independent data channels https://www.dest-unreach.org/socat/
      tmux # Terminal multiplexer https://github.com/tmux/tmux
      tree # Command to produce a depth indented directory listing https://mama.indstate.edu/users/ice/tree/
      glibcLocales # Locale data for the GNU C Library
      gnumake # Tool which controls the generation of executables and other non-source files https://www.gnu.org/software/make/
      nettools # Set of tools for controlling the network subsystem in Linux https://sourceforge.net/projects/net-tools/
      eza # Modern replacement for ls https://github.com/eza-community/eza
      delta # Syntax-highlighting pager for git and diff output https://github.com/dandavison/delta
      carapace # Multi-shell multi-command argument completer https://github.com/carapace-sh/carapace-bin
      fzf # Command-line fuzzy finder https://github.com/junegunn/fzf
      zoxide # Fast cd command that learns your habits https://github.com/ajeetdsouza/zoxide
      navi # Interactive cheatsheet tool for the command-line https://github.com/denisidoro/navi
      bundix # Creates Nix packages from Gemfiles https://github.com/nix-community/bundix
      rust-toolchain-fenix # from pkgs/default.nix
      cargo-completions # Shell completions for cargo
      yq-go # Portable command-line YAML processor https://github.com/mikefarah/yq
      tzdata # Time zone and daylight-saving time data https://www.iana.org/time-zones
      unzip # Extraction utility for archives compressed in .zip format https://infozip.sourceforge.net/UnZip.html
      zip # Compressor/archiver for creating and modifying zipfiles https://infozip.sourceforge.net/Zip.html
      docker-client # Pack, ship and run any application as a lightweight container https://www.docker.com/
      docker-compose # Multi-container orchestration for Docker https://github.com/docker/compose
      dust # More intuitive version of du in rust https://github.com/bootandy/dust
      fd # Simple, fast and user-friendly alternative to find https://github.com/sharkdp/fd
      just # Just a command runner https://github.com/casey/just
      procs # A modern replacement for ps written in Rust https://github.com/dalance/procs
      tealdeer # Very fast implementation of tldr in Rust https://github.com/dbrgn/tealdeer
      githooks # Simple Git hooks manager https://github.com/gabyx/githooks
      ranger # File manager with minimalistic curses interface https://ranger.github.io/
      colorized-logs # Tools for logs with ANSI color https://github.com/kilobyte/colorized-logs
      zellij # Terminal workspace with batteries included https://zellij.dev/
      hub # Command-line tool that makes git easier to use with GitHub https://hub.github.com/
      trash-cli # Command line interface to the freedesktop.org trashcan https://github.com/andreafrancia/trash-cli
      nodePackages_latest.nodejs # Event-driven I/O framework for the V8 JavaScript engine https://nodejs.org
      nodePackages.yarn # Fast, reliable, and secure dependency management for JavaScript https://yarnpkg.com/
      loadtest # HTTP load testing tool https://github.com/alexfernandez/loadtest
      prettier-plugin-awk # Prettier plugin for awk https://github.com/Beaglefoot/prettier-plugin-awk
      node2nix # Generate Nix expressions to build NPM packages https://github.com/svanderburg/node2nix
      nodePackages.prettier # Opinionated code formatter https://prettier.io/
      prettierd # prettier, as a daemon, for improved formatting speed https://github.com/fsouza/prettierd
      nodePackages.eslint # AST-based pattern checker for JavaScript https://eslint.org/
      nodePackages.bash-language-server # Language server for Bash https://github.com/bash-lsp/bash-language-server
      (bats.withLibraries (p: [
        p.bats-support
        p.bats-assert
      ])) # Bash Automated Testing System https://github.com/bats-core/bats-core
      git-ignore # Interactive CLI to generate .gitignore files https://github.com/sondr3/git-ignore
      http-server # Simple zero-configuration command-line HTTP server https://github.com/http-party/http-server
      cachix # install cache, for example, with: $HOME/.nix-profile/bin/cachix use nix-community
      (symlinkJoin {
        # kitty: Modern, hackable, featureful, OpenGL based terminal emulator https://sw.kovidgoyal.net/kitty/
        name = "kitty-with-python-packages";
        paths = [ kitty ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/kitty --set PYTHONPATH "${python3Packages.wcwidth}/lib/python3.13/site-packages"
        '';
      })
      dhcping # Send DHCP request to DHCP server for monitoring purposes https://www.mavetju.org/unix/general.php
      ipcalc # Simple IP network calculator (CIDR) https://gitlab.com/ipcalc/ipcalc
      arp-scan # ARP scanning and fingerprinting tool https://github.com/royhills/arp-scan
      xh # Friendly and fast tool for sending HTTP requests https://github.com/ducaale/xh
      dua # View disk space usage and delete unwanted data, fast https://github.com/Byron/dua-cli
      yazi # Blazing Fast Terminal File Manager
      kondo # A command-line tool to clean up your code
      universal-ctags # Maintained ctags implementation https://ctags.io/
      nixd # Nix language server https://github.com/nix-community/nixd/tree/main
      dockerfile-language-server # A language server for Dockerfiles powered by Node.js https://github.com/rcjsuen/dockerfile-language-server
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
      neovim # Vim-fork focused on extensibility and agility https://neovim.io
      mylua # see ./pkgs/default.nix
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
      # roslyn-ls # Language server behind C# Dev Kit for Visual Studio Code https://github.com/dotnet/vscode-csharp
      fsautocomplete # FsAutoComplete project (FSAC) provides a backend service for rich editing or intellisense features for editors https://github.com/fsharp/FsAutoComplete
      basedpyright # Type checker for the Python language (and lsp) https://github.com/detachhead/basedpyright
      uv # Extremely fast Python package installer and resolver, written in Rust https://docs.astral.sh/uv/
      powershell-editor-services # Common platform for PowerShell development support in any editor or application https://github.com/PowerShell/PowerShellEditorServices
    ])
    ++ (with llvmPackages_20; [
      clang-tools # Standalone command line tools for C++ development https://clangd.llvm.org/
      clangUseLLVM # C language family frontend for LLVM (wrapper script) https://clang.llvm.org/
      clang-manpages # Man pages for Clang https://clang.llvm.org/
      vim-language-server # VImScript language server, LSP for vim script https://github.com/iamcco/vim-language-server
      lua-language-server # Lua language server https://github.com/LuaLS/lua-language-server
      cspellls # Custom cspell language server made from the vscode extension
      hadolint # Dockerfile linter, validate inline bash https://github.com/hadolint/hadolint
      # pkg-config # do not install pkg-config to avoid conflicts with Ubuntu's pkg-config
      stylua # A Lua code formatter https://github.com/JohnnyMorganz/StyLua
      yamlfmt # An extensible command line tool or library to format yaml files https://github.com/google/yamlfmt
      openssh # Implementation of the SSH protocol https://www.openssh.com/
      # end of common basic packages
    ])
    ++ (
      if setup.wsl then
        [
          # wsl basic packages
          wslu # Collection of utilities for WSL https://github.com/wslutilities/wslu
          # end of wsl basic packages
        ]
      else
        [
          # non wsl basic packages
          android-tools # Android SDK platform tools https://developer.android.com/
          bitwarden-desktop # Secure and free password manager for all of your devices https://bitwarden.com/
          blanket # Improve focus and increase productivity by listening to ambient sounds https://github.com/rafaelmardojai/blanket
          eartag # Small and simple music tag editor https://gitlab.gnome.org/World/eartag
          eyedropper # Pick and format colors https://github.com/FineFindus/eyedropper
          forge-sparks # Get Git forges notifications https://github.com/rafaelmardojai/Forge-Sparks
          gnome-contacts # GNOME's integrated address book https://gitlab.gnome.org/GNOME/gnome-contacts
          polari # Internet Relay Chat (IRC) client https://gitlab.gnome.org/GNOME/polari
          gnome-podcasts # Podcast application for GNOME https://gitlab.gnome.org/World/podcasts
          gnome-solanum # Pomodoro timer for GNOME https://gitlab.gnome.org/World/Solanum
          gnome-tweaks # Tool to customize advanced GNOME 3 options https://gitlab.gnome.org/GNOME/gnome-tweaks
          gnome-extension-manager # Utility for browsing and installing GNOME Shell Extensions https://github.com/mjakeman/extension-manager
          hwloc # Portable abstraction of hierarchical architectures for high-performance computing https://www.open-mpi.org/projects/hwloc/
          keybase-gui # Keybase desktop client https://keybase.io/
          newsflash # Modern feed reader designed for the GNOME desktop https://gitlab.com/news-flash/news_flash_gtk
          obsidian # Powerful knowledge base on top of a local folder of plain text Markdown files https://obsidian.md
          onlyoffice-desktopeditors # Office suite that combines text, spreadsheet and presentation editors https://www.onlyoffice.com/
          openrgb-with-all-plugins # Open source RGB lighting control https://openrgb.org/
          pinta # Drawing/editing program modeled after Paint.NET https://www.pinta-project.com/
          remmina # Remote desktop client written in GTK https://remmina.org/
          shortwave # Find and listen to internet radio stations https://gitlab.gnome.org/World/Shortwave
          switcheroo # Image converter and manipulator https://gitlab.com/adhami3310/Switcheroo
          telegram-desktop-wrapped # Telegram Desktop messaging app https://desktop.telegram.org/
          textpieces # Swiss knife of text processing https://github.com/liferooter/textpieces
          vlc # Cross-platform media player and streaming server https://www.videolan.org/vlc/
          warp # Fast and secure file transfer https://apps.gnome.org/Warp/
          pear-desktop # YouTube Music Desktop App https://github.com/pear-devs/pear-desktop
          xclip # Tool to access the X clipboard from a console https://github.com/astrand/xclip
          nerd-fonts.caskaydia-cove # Nerd Fonts patched version of Cascadia Code
          nerd-fonts.symbols-only # Just the Nerd Font Icons
          smile # Emoji picker https://github.com/mijorus/smile
          ulauncher # Feature rich application Launcher for Linux https://github.com/Ulauncher/Ulauncher/
        ]
        ++ (with gnomeExtensions; [
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
          (gnome46Extensions.${focused-window-d-bus.extensionUuid})
        ])
      # end of non wsl basic packages
    )
    ++ (
      if setup.isNixOS then
        [
          # NixOS basic packages
          # end of NixOS basic packages
        ]
      else
        [
          # non NixOS basic packages
          # end of non NixOS basic packages
        ]
    )
  );
  non_basic_pkgs = lib.lists.optionals (!setup.basicSetup) (
    with pkgs;
    [
      # common non basic packages
      ookla-speedtest # Command line internet speedtest tool by Ookla https://www.speedtest.net/apps/cli
      slides # Terminal based presentation tool https://github.com/maaslalani/slides
      mermaid-cli # Generation of diagrams and flowcharts from text https://github.com/mermaid-js/mermaid-cli
      presenterm # Terminal slideshow tool https://github.com/mfontanini/presenterm
      hugo # Fast and flexible static site generator https://gohugo.io
      pagefind # Static search library https://pagefind.app/
      element-desktop # Feature-rich client for Matrix https://element.io/
      ccd2iso # Converts CCD/IMG CloneCD images to ISO format https://sourceforge.net/projects/ccd2iso/
      iat # ISO9660 analyzer tool https://sourceforge.net/projects/iat.berlios/
      apparmor-utils # Userspace utilities for AppArmor https://gitlab.com/apparmor/apparmor
      chart-releaser # Hosting Helm Charts via GitHub Pages and Releases https://github.com/helm/chart-releaser
      docker-show-context # Shows docker context in prompt https://github.com/pwaller/docker-show-context
      deno # Secure runtime for JavaScript and TypeScript https://deno.com/
      opentofu # Tool for building, changing, and versioning infrastructure safely and efficiently https://opentofu.org/
      krew # Package manager for kubectl plugins https://krew.sigs.k8s.io/
      kube-capacity # CLI that provides resource capacity metrics https://github.com/robscott/kube-capacity
      kail # Kubernetes log viewer https://github.com/boz/kail
      ketall # Like kubectl get all, but get really all resources https://github.com/corneliusweig/ketall
      ctop # Top-like interface for container metrics https://github.com/bcicen/ctop
      go # Go Programming Language https://go.dev/
      (lib.hiPrio gcc) # GNU Compiler Collection https://gcc.gnu.org/
      docker-slim # Minify and secure Docker containers https://github.com/slimtoolkit/slim
      asciinema # Terminal session recorder https://asciinema.org/
      bison # Yacc-compatible parser generator https://www.gnu.org/software/bison/
      cowsay # Program that generates ASCII pictures of a cow with a message https://github.com/piuccio/cowsay
      figlet # Program for making large letters out of ordinary text https://github.com/cmatsuoka/figlet
      fontforge # Font editor https://fontforge.org/
      # ghostscript # PostScript interpreter https://www.ghostscript.com/ # cups (for printing) depends on it on Ubuntu, so I'll keep it installed there and not on Nix
      gzip # GNU zip compression program https://www.gnu.org/software/gzip/
      inotify-tools # C library and CLI tools providing a simple interface to inotify https://github.com/inotify-tools/inotify-tools
      nmap # Network exploration tool and security / port scanner https://nmap.org/
      pandoc # Universal markup converter https://pandoc.org/
      ripgrep # Line-oriented search tool that recursively searches your current directory for a regex pattern https://github.com/BurntSushi/ripgrep
      screenfetch # Bash screenshot information tool https://github.com/KittyKatt/screenFetch
      shellcheck # Shell script analysis tool https://www.shellcheck.net/
      silver-searcher # Code searching tool similar to Ack, but faster https://github.com/ggreer/the_silver_searcher
      w3m # Text-based web browser https://github.com/tats/w3m
      temurin-bin-25 # Eclipse Temurin, Java Development Kit https://adoptium.net/
      maven # Build automation tool for Java https://maven.apache.org/
      (azure-cli.withExtensions [ azure-cli.extensions.containerapp ]) # Microsoft Azure command-line interface https://github.com/Azure/azure-cli
      kubectl # Kubernetes CLI https://kubernetes.io/
      kubespy # Tools for observing Kubernetes resources in real time https://github.com/pulumi/kubespy
      dive # Tool for exploring each layer in a docker image https://github.com/wagoodman/dive
      kubernetes-helm # Package manager for Kubernetes https://helm.sh/
      istioctl # Istio command-line tool https://istio.io/
      tflint # Terraform linter https://github.com/terraform-linters/tflint
      gh # GitHub CLI tool https://cli.github.com/
      github-copilot-cli # GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal. https://github.com/github/copilot-cli
      k9s # Kubernetes CLI to manage your clusters in style https://k9scli.io/
      awscli2 # Unified tool to manage AWS services https://aws.amazon.com/cli/
      k3d # Helper to run k3s in Docker https://k3d.io/
      act # Run your GitHub Actions locally https://github.com/nektos/act
      kn # Knative command-line interface https://knative.dev/
      func # Knative Functions CLI https://github.com/knative/func
      kubecolor # Colorize kubectl output https://github.com/hidetatz/kubecolor
      k6 # Modern load testing tool, using Go and JavaScript https://k6.io/
      xlsx2csv # Convert Excel XLSX files to CSV format https://github.com/dilshod/xlsx2csv
      clolcat # Like lolcat but faster https://github.com/ooJaan/clolcat
      bandwhich # Terminal bandwidth utilization tool https://github.com/imsnif/bandwhich
      cargo-update # Cargo subcommand for updating installed crates https://github.com/nabijaczleweli/cargo-update
      cargo-edit # Tool for managing cargo dependencies https://github.com/killercup/cargo-edit
      cargo-expand # Subcommand to show result of macro expansion https://github.com/dtolnay/cargo-expand
      cargo-outdated # Cargo subcommand for displaying outdated dependencies https://github.com/kbknapp/cargo-outdated
      cargo-watch # Watches over your Cargo project's source https://github.com/watchexec/cargo-watch
      cargo-binstall # Install Rust binaries instead of building from source https://github.com/cargo-bins/cargo-binstall
      gping # Ping, but with a graph https://github.com/orf/gping
      grex # Command-line tool for generating regular expressions https://github.com/pemistahl/grex
      sccache # Compiler caching tool https://github.com/mozilla/sccache
      tokei # Display statistics about your code https://github.com/XAMPPRocky/tokei
      gox # Dead simple, no frills Go cross compile tool https://github.com/mitchellh/gox
      manifest-tool # Tool for inspecting and creating manifests for multi-architecture container images https://github.com/estesp/manifest-tool
      shfmt # Shell parser, formatter, and interpreter https://github.com/mvdan/sh
      neofetch # Fast, highly customizable system info script https://github.com/dylanaraps/neofetch
      imagemagick # Software suite to create, edit, compose, or convert bitmap images https://imagemagick.org/
      kubectx # Faster way to switch between clusters and namespaces in kubectl https://github.com/ahmetb/kubectx
      lazydocker # Simple terminal UI for docker and docker-compose https://github.com/jesseduffield/lazydocker
      fabric-ai # Open-source framework for augmenting humans using AI https://github.com/danielmiessler/fabric
      nixpkgs-review # Review pull requests on nixpkgs https://github.com/Mic92/nixpkgs-review
      bacon # Rust background code checker
      bacon-ls # Language server for Rust using Bacon diagnostics
      cargo-info # Cargo subcommand to show crates info from crates.io
      rusty-man # Command-line viewer for documentation generated by rustdoc
      wiki-tui # Simple and easy to use Wikipedia Text User Interface
      lynx # text web browser https://lynx.invisible-island.net/
      fdupes # program for identifying or deleting duplicate files residing within specified directories https://github.com/adrianlopezroche/fdupes
      wezterm # GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust
      sqlite # Self-contained, serverless, zero-configuration, transactional SQL database engine https://www.sqlite.org/
      ladybird # a truly independent web browser https://ladybird.org/
      ffmpeg # the leading multimedia framework https://www.ffmpeg.org/
      fsarchiver # File system archiver for linux https://www.fsarchiver.org/
      stress # Simple workload generator for POSIX systems. https://people.seas.harvard.edu/~apw/stress/
      graphviz # Graph visualization tools https://graphviz.org/
      aw-watcher-media-player # [Custom package] Watcher of system's currently playing media for ActivityWatch
      opencode # AI coding agent built for the terminal https://opencode.ai/ https://github.com/sst/opencode
      audacity # Sound editor with graphical UI https://www.audacityteam.org/
      coolercontrol.coolercontrol-gui # Monitor and control your cooling devices (GUI) https://gitlab.com/coolercontrol/coolercontrol
      browsh # Fully-modern text-based browser, rendering to TTY and browsers https://www.brow.sh/
      # dotnet # see ./pkgs/dotnet
      # end of common non basic packages
    ]
    ++ (
      if setup.wsl then
        [
          # wsl non basic packages
          # end of wsl non basic packages
        ]
      else
        [
          # non wsl non basic packages
          dconf2nix # Convert dconf files to Nix expressions https://github.com/gvolpe/dconf2nix
          slack # Desktop client for Slack https://slack.com/
          discord # All-in-one voice and text chat for gamers https://discord.com/
          obs-studio # Free and open source software for video recording and live streaming https://obsproject.com/
          kdePackages.kdenlive # Video editor by KDE https://kdenlive.org/
          glaxnimate # Simple vector animation program https://glaxnimate.mattbas.org/
          # openshot-qt # Free, open-source video editor http://openshot.org/ # todo: depending on qtwebengine, which is insecure, try to add it back later
          wireshark # Network protocol analyzer https://www.wireshark.org/
          brave # Privacy-oriented browser https://brave.com/
          orca-slicer # G-code generator for 3D printers https://github.com/SoftFever/OrcaSlicer
          fritzing # Electronic design automation software https://fritzing.org/
          mqttx # MQTT 5.0 client desktop application https://mqttx.app/
          mqtt-explorer # MQTT client https://mqtt-explorer.com/
          kdePackages.k3b # Full-featured CD/DVD/Blu-ray burning and ripping application
          cdrtools # Highly portable CD/DVD/BluRay command line recording software
          dvdauthor # Tools for generating DVD files to be played on standalone DVD players https://dvdauthor.sourceforge.net/
          # dvdstyler # DVD authoring software https://www.dvdstyler.org/ # todo: not working, check back later
          doublecmd # Two-panel graphical file manager written in Pascal https://github.com/doublecmd/doublecmd
          tor-browser # Privacy-focused browser routing traffic through the Tor network https://www.torproject.org/
          tesseract # OCR engine https://github.com/tesseract-ocr/tesseract
          calibre # Comprehensive e-book software https://calibre-ebook.com/
          # fontconfig # Library for font customization and configuration http://fontconfig.org/ # doesn't make sense to uninstall from Ubuntu as it has a lot of dependencies
          gparted # Graphical disk partitioning tool https://gparted.org/
          terminator # Terminal emulator with support for tiling and tabs https://gnome-terminator.org/
          transmission_4-gtk # Fast, easy and free BitTorrent client https://www.transmissionbt.com/
          transmission-remote-gtk # GTK remote control for the Transmission BitTorrent client https://github.com/transmission-remote-gtk/transmission-remote-gtk
          onedriver # A native Linux filesystem for Microsoft OneDrive https://github.com/jstaf/onedriver
          # end of non wsl non basic packages
        ]
    )
    ++ (
      if setup.isNixOS then
        [
          # NixOS non basic packages
          vscode-fhs # Visual Studio Code with FHS environment https://code.visualstudio.com/
          microsoft-edge # Web browser from Microsoft https://www.microsoft.com/edge
          # protonup-qt # to use with steam
          # end of NixOS non basic packages
        ]
      else
        (
          if setup.wsl then
            [
              # non NixOS wsl non basic packages
              # end of non NixOS wsl non basic packages
            ]
          else
            [
              # non NixOS non wsl non basic packages
              vscode # Visual Studio Code https://code.visualstudio.com/
              # end of non NixOS non wsl non basic packages
            ]
        )
    )
  );
  stable_basic_pkgs = (
    # with pkgs-stable;
    [
      # common basic packages (stable)
      # end of common basic packages (stable)
    ]
    ++ (
      if setup.wsl then
        [
          # wsl basic packages (stable)
          # enf of wsl basic packages (stable)
        ]
      else
        [
          # non wsl basic packages (stable)
          # end of non wsl basic packages (stable)
        ]
    )
    ++ (
      if setup.isNixOS then
        [
          # NixOS basic packages (stable)
          # end of NixOS basic packages (stable)
        ]
      else
        [
          # non NixOS basic packages (stable)
          # end of non NixOS basic packages (stable)
        ]
    )
  );
  stable_non_basic_pkgs = lib.lists.optionals (!setup.basicSetup) (
    # with pkgs-stable;
    [
      # common non basic packages (stable)
      # end of common non basic packages (stable)
    ]
    ++ (
      if setup.wsl then
        [
          # wsl non basic packages (stable)
          # end of wsl non basic packages (stable)
        ]
      else
        [
          # non wsl non basic packages (stable)
          # end of non wsl non basic packages (stable)
        ]
    )
    ++ (
      if setup.isNixOS then
        [
          # NixOS non basic packages (stable)
          # enf of NixOS non basic packages (stable)
        ]
      else
        (
          if setup.wsl then
            [
              # non NixOS wsl non basic packages (stable)
              # end of non NixOS wsl non basic packages (stable)
            ]
          else
            [
              # non NixOS non wsl non basic packages (stable)
              # end of non NixOS non wsl non basic packages (stable)
            ]
        )
    )
  );
  all_packages = basic_pkgs ++ non_basic_pkgs ++ stable_basic_pkgs ++ stable_non_basic_pkgs;
in
{
  home.packages = all_packages;
}
