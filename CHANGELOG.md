<!--
SPDX-FileCopyrightText: 2022 Jakob Fritz <j.fritz@fz-juelich.de>

SPDX-License-Identifier: CC0-1.0
-->

# Changelog

## v0.6

- Fixed issue for mirroring code and querying pipeline-status
when triggered by Pull-request
- Updated to use node20 instead of deprecated node16
(in checkout and upload-artifact action)
- Removed the actions-permissions action as it is deprecated
and was not updated since march 2023
- Set the needed permission for all actions
(according to the removed actions-permissions action)

## v0.5

- Fixed bug with downloading artifacts
- More verbose output while mirroring

## v0.4

- Added github action permission advisor
- Updated Readme for usage of this action in combination with Jacamar

## v0.3

- Added changelog
- Expanded Readme and added section on how to use with pull-requests
- Now able to pull artifacst from Gitlab and upload as Github-Artifacts
- Only push current branch to Gitlab instead of mirroring the full git

## v0.2

- Strongly expanded Readme
- Added combined action (mirroring & get_state)

## v0.1

- Initial version
