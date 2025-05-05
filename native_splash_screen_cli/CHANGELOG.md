## 0.1.0

- Initial release of the CLI tool for generating splash screen definitions.
- Generate the `native_splash_screen.yaml` config file.
- Reads from `native_splash_screen.yaml` config file.
- Generates platform-specific splash code (e.g., C headers).
- Supports:
  - Custom and default flavors (release/debug/profile/flavors)
  - Fallback logic per platform
  - Multiple color formats (hex, rgba, argb, etc.)
- Designed for future multi-platform expansion.