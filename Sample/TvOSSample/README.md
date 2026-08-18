# Rakuten Analytics tvOS Sample

Minimal Apple TV sample app that integrates the local `RakutenAnalytics` Swift package and exercises:

- SDK initialization and RAT endpoint configuration
- SwiftUI automatic page visits (`rviewOnAppear`)
- UIKit automatic page visits (`UIViewController` swizzling)
- Manual custom event tracking

## Requirements

- Xcode 26 or later
- tvOS 15.0 or later (simulator or device)
- tvOS platform components installed in Xcode (**Settings → Components**)

## Run

1. Open `Sample/TvOSSample/TvOSSample.xcodeproj` in Xcode.
2. If Xcode prompts to resolve packages, allow it to fetch dependencies.
3. Select the **TvOSSample** scheme and an Apple TV simulator.
4. Build and run.

The sample links the repository root Swift package (`Package.swift` at `../../` relative to this project) the same way as the iOS samples under `Sample/RakutenAnalyticsSample.xcodeproj`.

## Notes

- Features unavailable on tvOS (WebKit app-to-web tracking, cellular metadata, IDFA, geo by default) are not configured in this sample.
- Use debug logging to verify events in the Xcode console.
