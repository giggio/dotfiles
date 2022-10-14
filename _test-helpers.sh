BATS_LOCATION=`which bats`;
BATS_LOCATION=`echo "${BATS_LOCATION%/*/*/*/*}"`
if ! [ -f "$BATS_LOCATION/bats-assert/load.bash" ]; then
  npm install -g bats-assert
fi
load "$BATS_LOCATION/bats-assert/load.bash"
if ! [ -f "$BATS_LOCATION/bats-support/load.bash" ]; then
  npm install -g bats-support
fi
load "$BATS_LOCATION/bats-support/load.bash"
SUPPORT_DIR=$BATS_TEST_DIRNAME/.testsupport
if ! [ -f $SUPPORT_DIR/bats-mock.bash ]; then
  if ! [ -d $SUPPORT_DIR ]; then
    mkdir $SUPPORT_DIR
  fi
  \curl -fsSL  --output $SUPPORT_DIR/bats-mock.bash https://raw.githubusercontent.com/grayhemp/bats-mock/master/src/bats-mock.bash
fi
load $SUPPORT_DIR/bats-mock.bash
