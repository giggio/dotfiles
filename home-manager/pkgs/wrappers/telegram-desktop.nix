{ writeTextFile, stdenv, gcc, makeWrapper, telegram-desktop, ... }:

# this is only needed because of ecryptfs which does not implement some syscalls

let
  telegramRenameFallback = stdenv.mkDerivation {
    pname = "rename-fallback";
    version = "1.0";

    # Inline C source file produced inside the derivation
    srcFile = writeTextFile {
      name = "rename_fallback.c";
      text = ''
        #define _GNU_SOURCE
        #include <dlfcn.h>
        #include <errno.h>
        #include <fcntl.h>
        #include <unistd.h>
        #include <sys/types.h>

        typedef ssize_t (*copy_file_range_t)(
            int, off_t *, int, off_t *, size_t, unsigned int);

        typedef int (*renameat2_t)(
            int, const char *, int, const char *, unsigned int);

        ssize_t copy_file_range(
            int fd_in, off_t *off_in,
            int fd_out, off_t *off_out,
            size_t len, unsigned int flags)
        {
            static copy_file_range_t real_cfr = NULL;
            if (!real_cfr) {
                real_cfr = (copy_file_range_t)dlsym(RTLD_NEXT, "copy_file_range");
                if (!real_cfr) {
                    errno = ENOSYS;
                    return -1;
                }
            }

            if (flags != 0) {
                errno = EINVAL;
                return -1;
            }

            char buf[65536];
            ssize_t n = read(fd_in, buf, sizeof buf < len ? sizeof buf : len);
            if (n <= 0) return n;
            return write(fd_out, buf, n);
        }

        int renameat2(
            int olddirfd, const char *oldpath,
            int newdirfd, const char *newpath,
            unsigned int flags)
        {
            static renameat2_t real_renameat2 = NULL;
            if (!real_renameat2) {
                real_renameat2 = (renameat2_t)dlsym(RTLD_NEXT, "renameat2");
                if (!real_renameat2) {
                    errno = ENOSYS;
                    return -1;
                }
            }

            if (flags == 2 /* RENAME_EXCHANGE */) {
                errno = EINVAL;
                return -1;
            }

            return real_renameat2(olddirfd, oldpath, newdirfd, newpath, flags);
        }
      '';
    };

    nativeBuildInputs = [ gcc makeWrapper ];

    unpackPhase = "true"; # Prevent Nix from trying to untar anything
    buildPhase = ''
      mkdir -p $out/lib
      gcc -shared -fPIC -o $out/lib/rename_fallback.so ${telegramRenameFallback.srcFile} -ldl
    '';
    installPhase = "true";
  };
in
stdenv.mkDerivation {
  pname = "telegram-desktop-wrapped";
  version = "1.0";

  buildInputs = [ makeWrapper ];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin

    # Copy everything except the DBus service file
    mkdir -p $out/share/dbus-1/services
    cp -r ${telegram-desktop}/share/* $out/share/
    rm -f $out/share/dbus-1/services/org.telegram.desktop.service
    # Recreate a writable service file with the correct Exec path
    sed "s|Exec=.*|Exec=$out/bin/Telegram|" ${telegram-desktop}/share/dbus-1/services/org.telegram.desktop.service > \
      $out/share/dbus-1/services/org.telegram.desktop.service

    makeWrapper ${telegram-desktop}/bin/Telegram $out/bin/Telegram --set LD_PRELOAD "${telegramRenameFallback}/lib/rename_fallback.so"
  '';

}
