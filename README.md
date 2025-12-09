# XCStringsPlugin

A Swift Package Manager build tool plugin that generates type-safe Swift symbols from `.xcstrings` String Catalog files. Think of it as **STRING_CATALOG_GENERATE_SYMBOLS for SPM**

## Background

Starting with Xcode 26, you can enable `STRING_CATALOG_GENERATE_SYMBOLS` to automatically generate type-safe symbols from your String Catalogs. This lets you reference localized strings using compile-time checked symbols instead of error-prone string literals:

```swift
// Instead of this:
Text("welcome_message")

// You can write this:
Text(.welcomeMessage)
```

However, this feature only works when building from Xcode - it doesn't work with `swift build` or `swift test` from the command line.

**XCStringsPlugin bridges this gap.** It uses the same `xcstringstool` that Xcode uses under the hood, allowing your SPM packages to build with type-safe string symbols from both Xcode and the command line.

## Requirements

- macOS with Xcode 26 or later installed
- Swift 6.2 or later

## Installation

Add the plugin as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sveinhal/XCStringsPlugin.git", from: "1.0.0")
]
```

Then apply the plugin to your target(s):

```swift
targets: [
    .target(
        name: "MyLibrary",
        plugins: [
            .plugin(name: "GenerateSymbols", package: "XCStringsPlugin")
        ]
    )
]
```

## Xcode Configuration

When building from Xcode, the plugin does nothing, and expects Xcode's built-in symbol generation to do the job. Make sure you have enabled the build setting:

```
STRING_CATALOG_GENERATE_SYMBOLS = YES
```

You can set this in your Xcode project's Build Settings, or add it to an `.xcconfig` file.

## How It Works

The plugin detects `.xcstrings` files in your target and generates corresponding Swift symbol files:

- **When building with `swift build`**: The plugin runs `xcstringstool generate-symbols` to create Swift files with type-safe accessors.
- **When building from Xcode**: The plugin returns no commands, and thus does nothing, allowing Xcode's native `STRING_CATALOG_GENERATE_SYMBOLS` mechanism to handle generation instead.

This dual approach prevents conflicts (duplicate symbol definitions) while ensuring your package builds correctly in both environments.

## Usage Example

Given a `Localizable.xcstrings` file with these keys:

```json
{
  "welcome_message": { "localizations": { "en": { "stringUnit": { "value": "Welcome!" } } } },
  "item_count %lld": { "localizations": { "en": { "stringUnit": { "value": "%lld items" } } } }
}
```

You can use the generated symbols in your code:

```swift
import SwiftUI

struct ContentView: View {
    let count: Int

    var body: some View {
        VStack {
            Text(.welcomeMessage)
            Text(.itemCount(count))
        }
    }
}
```

## Limitations

- **macOS only**: The plugin requires `xcrun` to locate `xcstringstool`, which is only available on macOS with Xcode installed.
- **Xcode 26+**: The `xcstringstool` with `generate-symbols` support is only available in Xcode 26 and later.

## License

MIT License. See [LICENSE](LICENSE) for details.
