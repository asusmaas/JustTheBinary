# JustTheBinary — slim iOS fork

OpenCV 4.12.0 as a SwiftPM binary target, repacked for iOS apps from
[r0ml/JustTheBinary](https://github.com/r0ml/JustTheBinary) release 4.12.1.

|                    | upstream 4.12.1 | this fork |
|--------------------|-----------------|-----------|
| download           | 1.47 GB         | 97 MB     |
| extracted, per DerivedData | 5.8 GB  | 532 MB    |

What differs from upstream:

- **iOS only**: the device (arm64) and Simulator (arm64) slices. No macOS,
  Mac Catalyst or x86_64 (Intel Simulator) slices.
- **Debug symbols stripped** from the static archives.
- **Shallow framework layout in both slices**, so Simulator builds need no
  `fixshallow` step.
- **`MinimumOSVersion` in each framework's `Info.plist`**, which App Store
  Connect otherwise rejects with error 90530.

## Use

```swift
.package(url: "https://github.com/asusmaas/JustTheBinary.git", exact: "4.12.1-slim")
```

Pin with `exact:`. This fork carries upstream's tags, so a version range
resolves to upstream's full-size releases instead.

## Regenerate

`slim-opencv.sh` turns an upstream release zip into the slim one:

```bash
curl -L -o upstream.zip \
  https://github.com/r0ml/JustTheBinary/releases/download/4.12.1/OpenCV.xcframework.zip
./slim-opencv.sh upstream.zip out/
```

Upload `out/OpenCV.xcframework.zip` as the asset of a new release, then point
`url` and `checksum` in `Package.swift` at it.

## License

OpenCV is licensed under the Apache License 2.0; see [LICENSE](LICENSE).
