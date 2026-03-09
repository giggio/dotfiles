#!/usr/bin/env bats

setup() {

  load '_test-helpers.sh'
  rm -f "$BATS_TMPDIR"/bats-mock.*
  curl_mock="$(mock_create)"

  # shellcheck disable=SC1091
  source "$BATS_TEST_DIRNAME"/_functions.sh --curl "$curl_mock"
}
