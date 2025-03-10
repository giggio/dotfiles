#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {

  load '_test-helpers.sh'
  rm -f "$BATS_TMPDIR"/bats-mock.*
  curl_mock="$(mock_create)"

  source "$BATS_TEST_DIRNAME"/_functions.sh --curl "$curl_mock"
}
