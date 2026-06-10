# CI

This repository uses `main` as the development branch. Every pushed branch runs the iOS test suite in GitHub Actions.

Release branches use the form `rX.Y.Z`, for example `r1.2.3`. A release branch also runs a version check: the app target's `MARKETING_VERSION` must equal `X.Y.Z`.

This CI setup does not archive the app, upload builds, or push anything to App Store Connect.

## Workflows

`iOS Tests` runs on every branch push:

```sh
scripts/ci/run_tests.sh
```

`Release Version Check` runs on pushed branches matching `r*.*.*`:

```sh
scripts/ci/check_release_branch_version.sh
```

The workflow branch glob is intentionally broad. The script enforces the stricter `rX.Y.Z` format and fails if the app version does not match.

## Local Checks

Run the same version check locally before pushing a release branch:

```sh
scripts/ci/check_release_branch_version.sh r1.1.0
```

Run the test suite locally:

```sh
scripts/ci/run_tests.sh
```
