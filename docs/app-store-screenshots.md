# App Store Screenshots

Use the screenshot capture script to generate deterministic App Store screenshots from seeded UI test data.

```sh
scripts/screenshots/capture_app_store_screenshots.sh
```

The script writes PNG files to:

```text
AppStoreScreenshots/iPhone-6.9
```

The output directory is ignored by Git so generated screenshots do not get committed accidentally.

To override the simulator destination:

```sh
DESTINATION='platform=iOS Simulator,id=<SIMULATOR_UDID>' scripts/screenshots/capture_app_store_screenshots.sh
```

To override the output directory:

```sh
SCREENSHOT_DIR=/tmp/personal-tracker-screenshots scripts/screenshots/capture_app_store_screenshots.sh
```
