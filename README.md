# ProductSpotter

A Flutter prototype (Android and iOS from one codebase) that identifies a product from a photo and offers to list it on a marketplace. It was built to demonstrate one architectural idea: image recognition should be a separate service from marketplace listing, so a failure or change in the listing API cannot block recognition.

## Status

Working prototype. Recognition currently returns mock results, and the marketplace listing button is a placeholder.

| Feature | State |
|---|---|
| Take a photo or pick one from the gallery | Implemented |
| Product recognition | Mocked (returns sample product, category and price range) |
| Google Cloud Vision integration | Stubbed in `_recognizeWithGoogleVision()`; needs an API key to enable |
| eBay listing | Placeholder button; no API calls yet |

## Architecture

Tightly coupled version, where one failing call breaks everything:

```
Camera -> image processing -> wait for marketplace shipping API -> result
```

This prototype separates the two concerns:

```
Camera -> image recognition (independent)
              |
              v
      recognized product --> listing service (separate, replaceable)
```

If the listing service is unavailable, recognition still works.

## Tech stack

Flutter and Dart, Material Design 3, camera and gallery access, Google Cloud Vision (optional, not enabled by default).

## Run it

```bash
flutter create product_spotter
cd product_spotter
# replace lib/main.dart and pubspec.yaml with the files from this repository
flutter pub get
flutter run
```

Add the camera permissions from `ANDROID_MANIFEST_SNIPPET.txt` and `IOS_PERMISSIONS_SNIPPET.txt` to `AndroidManifest.xml` and `Info.plist`. Testing on a physical device is recommended, because emulator cameras are unreliable.

## Enabling real recognition

1. Create a Google Cloud Vision API key.
2. Fill in `_recognizeWithGoogleVision()` in `main.dart` and call it in place of the mock.
3. Keep the key out of source control (use environment configuration or a secrets file).

## Next steps

- [ ] Real recognition through Google Cloud Vision
- [ ] eBay OAuth and listing creation
- [ ] Unit tests for the recognition and listing services

## License

MIT.
