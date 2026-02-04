# see how to load libraries: https://bats-core.readthedocs.io/en/stable/writing-tests.html#bats-load-library-load-system-wide-libraries

libs_to_npm_install='bats-assert bats-support'
libs_to_load="$libs_to_npm_install bats-mock"
libs_not_installed=false
for lib in $libs_to_load; do
  if ! bats_load_safe "$lib"; then
    libs_not_installed=true
    break
  fi
done
if $libs_not_installed; then
  local_bats_lib_path=${XDG_DATA_HOME:-$HOME/.local/share}/bats
  if [ -v BATS_LIB_PATH ]; then
    export BATS_LIB_PATH=$local_bats_lib_path/libs:${BATS_LIB_PATH}
  else
    export BATS_LIB_PATH=$local_bats_lib_path/libs
  fi
  mkdir -p "$local_bats_lib_path"/lib/node_modules/
  if ! [ -d "$local_bats_lib_path"/libs ]; then
    ln -s "$local_bats_lib_path"/lib/node_modules "$local_bats_lib_path"/libs
  fi
  for lib in $libs_to_npm_install; do
    if ! [ -f "$local_bats_lib_path/libs/$lib/load.bash" ] && ! [ -f "$local_bats_lib_path/libs/$lib/load.bash" ]; then
      npm install -g --prefix "$local_bats_lib_path" "$lib"
    fi
  done
  if ! [ -f "$local_bats_lib_path"/libs/bats-mock ]; then
    \curl -fsSL --output "$local_bats_lib_path"/libs/bats-mock https://raw.githubusercontent.com/grayhemp/bats-mock/master/src/bats-mock.bash
  fi
fi

for lib in $libs_to_load; do
  bats_load_library "$lib"
done
