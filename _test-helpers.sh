BATS_LOCATION=`which bats`;
BATS_LOCATION=`echo "${BATS_LOCATION%/*/*/*/*}"`
echo "$BATS_LOCATION/bats-assert/load.bash"
load "$BATS_LOCATION/bats-assert/load.bash"
load "$BATS_LOCATION/bats-support/load.bash"
