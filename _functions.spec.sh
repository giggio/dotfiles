#!/usr/bin/env bats

setup() {

  load '_test-helpers.sh'
  rm -f $BATS_TMPDIR/bats-mock.*
  curl_mock="`mock_create`"

  . $BATS_TEST_DIRNAME/_functions.sh --curl "$curl_mock"
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
  run githubLatestTagByVersion x/y
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
  run githubLatestTagByVersion x/y
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
  run githubLatestTagByVersion x/y
  assert_output "1.2.3"
}

@test "Compare equal versions" {
  run versionsEqual "1.2.3" "1.2.3"
  assert_success
}

@test "Compare equal versions,  first one has a v" {
  run versionsEqual "v1.2.3" "1.2.3"
  assert_success
}

@test "Compare equal versions, second one has a v" {
  run versionsEqual "1.2.3" "v1.2.3"
  assert_success
}

@test "Compare different versions" {
  run versionsEqual "1.2.3" "5.2.3"
  assert_failure
}

@test "Compare different versions with versionsDifferent" {
  run versionsDifferent "1.2.3" "5.2.3"
  assert_success
}

@test "Gets release download url without test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "test",
        "browser_download_url": "z"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y
  assert_equal "`mock_get_call_num $curl_mock`" '1'
  assert_equal "`mock_get_call_args $curl_mock`" '-fsSL https://api.github.com/repos/x/y/releases'
  assert_output 'z'
}

@test "Gets release download url from multiple releases with one being a prerelease, without test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "test1",
        "browser_download_url": "z"
      }
    ]
  },
  {
    "prerelease": true,
    "assets": [
      {
        "name": "test2",
        "browser_download_url": "z"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y test1
  assert_output 'z'
}

@test "Gets release download url with simple test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "test",
        "browser_download_url": "z"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y test
  assert_output 'z'
}

@test "Gets release download url with named test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "name1",
        "browser_download_url": "z"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y '|test("name1")'
  assert_output 'z'
}

@test "Gets release download url with regex test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "eza-accoutrements-v0.10.1.zip",
        "browser_download_url": "a"
      },
      {
        "name": "eza-linux-armv7-v0.10.1.zip",
        "browser_download_url": "b"
      },
      {
        "name": "eza-linux-x86_64-musl-v0.10.1.zip",
        "browser_download_url": "c"
      },
      {
        "name": "eza-linux-x86_64-v0.10.1.zip",
        "browser_download_url": "right one"
      },
      {
        "name": "eza-macos-x86_64-v0.10.1.zip",
        "browser_download_url": "d"
      },
      {
        "name": "eza-vendored-source-v0.10.1.zip",
        "browser_download_url": "e"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y "^eza-linux-x86_64(?!-musl)"
  assert_output 'right one'
}

@test "Gets release download url from multiple releases with test" {
  mock_set_output "$curl_mock" '[
  {
    "prerelease": false,
    "assets": [
      {
        "name": "test1",
        "browser_download_url": "z"
      }
    ]
  },
  {
    "prerelease": false,
    "assets": [
      {
        "name": "test2",
        "browser_download_url": "z"
      }
    ]
  }
]'
  run githubReleaseDownloadUrl x/y test1
  assert_output 'z'
}
