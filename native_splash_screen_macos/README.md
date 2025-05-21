# native_splash_screen_macos

The Macos implementation for the [`native_splash_screen`](https://pub.dev/packages/native_splash_screen) Flutter plugin.

> **This package is not intended for direct use.**  
> It is automatically used on Macos when you depend on the main `native_splash_screen` plugin.

## Features

- Native AppKit splash screen window.
- Customizable via a YAML config (`native_splash_screen.yaml`) using the [`native_splash_screen_cli`](https://pub.dev/packages/native_splash_screen_cli) tool.
- Supports:
  - Configurable image, size, colors, blur, and border radius
  - Close animations (fade, slide up/down, none)

## Platform Support

This plugin is intended for **desktop Macos** environments.

## Usage

You do **not** need to install this package directly.  
Add the main plugin instead:

```yaml
dependencies:
  native_splash_screen: ^2.1.0
```

## License

BSD 3-Clause