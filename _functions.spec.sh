#!/usr/bin/env bats

BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
. $BASEDIR/_functions.sh

setup() {

  load '_test-helpers.sh'
  # load 'test_helper/bats-support/load'
  # load 'test_helper/bats-assert/load'
  # ... the remaining setup is unchanged

  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  # DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # make executables in src/ visible to PATH
  # PATH="$DIR/../src:$PATH"
}

@test "Test simple version compare" {
  run getLatestVersion "1.0.0
2.0.0"
  assert_output "2.0.0"
}

@test "Test several versions" {
  run getLatestVersion "1.0.0
2.0.0
3.0.0
4.0.0
5.0.0"
  assert_output "5.0.0"
}

@test "Test several versions unordered" {
  run getLatestVersion "6.0.0
2.0.0
7.0.0
4.0.0
1.0.0"
  assert_output "7.0.0"
}

@test "Test several versions unordered and with pre-release" {
  run getLatestVersion "6.0.0
2.0.0
7.0.0-alpha
4.0.0
1.0.0"
  assert_output "7.0.0-alpha"
}

@test "Test version compare with pre-release" {
  run getLatestVersion "1.0.0
1.0.0-alpha"
  assert_output "1.0.0"
}

@test "Test equal versions" {
  run getLatestVersion "1.0.0
1.0.0"
  assert_output "1.0.0"
}

@test "Test releases with a single version" {
  function curl() {
    echo '[
  {
    "prerelease": false,
    "tag_name": "v0.4.3"
  }
]'
  }
  run githubLatestReleaseVersion x/y
  assert_output "0.4.3"
}

@test "Test releases with a two versions" {
  function curl() {
    echo '[
  {
    "prerelease": false,
    "tag_name": "v0.4.3"
  },
  {
    "prerelease": false,
    "tag_name": "1.3.2"
  }
]'
  }
  run githubLatestReleaseVersion x/y
  assert_output "1.3.2"
}

@test "Test releases with a two versions, one pre-release" {
  function curl() {
    echo '[
  {
    "prerelease": false,
    "tag_name": "0.4.3"
  },
  {
    "prerelease": true,
    "tag_name": "1.3.2"
  }
]'
  }
  run githubLatestReleaseVersion x/y
  assert_output "0.4.3"
}

@test "Test tags with a single version" {
  function curl() {
    echo '[
  {
    "ref": "refs/tags/0.4.3"
  }
]'
  }
  run githubLatestTag x/y
  assert_output "0.4.3"
}

@test "Test tags with a single version with v version" {
  function curl() {
    echo '[
  {
    "ref": "refs/tags/v0.4.3"
  }
]'
  }
  run githubLatestTag x/y
  assert_output "0.4.3"
}

@test "Test tags with two versions" {
  function curl() {
    echo '[
  {
    "ref": "refs/tags/v0.4.3"
  },
  {
    "ref": "refs/tags/1.2.3"
  }
]'
  }
  run githubLatestTag x/y
  assert_output "1.2.3"
}
