<!--
SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>

SPDX-License-Identifier: CC0-1.0
-->

# Changelog

## 0.8

- Added code to trigger a new pipeline when no code changed
(e.g. used in reruns or in scheduled pipelines)
- Updated README to correct spelling errors

## 0.7

- Added environment variable to specify which branch shall be mirrored
- Updated naming scheme for artifacts, as previous one lead to issues when used in combination with parallel-matrix in GitLab
- Added Ruff as linter

## v0.6

- Fixed issue for mirroring code and querying pipeline-status
when triggered by Pull-request
- Updated to use node20 instead of deprecated node16
(in checkout and upload-artifact action)
- Removed the actions-permissions action as it is deprecated
and was not updated since March 2023
- Set the needed permission for all actions
(according to the removed actions-permissions action)

## v0.5

- Fixed bug with downloading artifacts
- More verbose output while mirroring

## v0.4

- Added GitHub action permission advisor
- Updated README for usage of this action in combination with Jacamar

## v0.3

- Added changelog
- Expanded README and added section on how to use with pull-requests
- Now able to pull artifacts from GitLab and upload as GitHub-Artifacts
- Only push current branch to GitLab instead of mirroring the full git

## v0.2

- Strongly expanded README
- Added combined action (mirroring & get_state)

## v0.1

- Initial version
