# 🖼️ native_splash_screen

> Native splash screens provide faster startup visuals, smoother transitions, and eliminate the first-frame jank common with typical Flutter splash workarounds.

**native_splash_screen** is a Flutter plugin that delivers fully configurable, animated splash screens on **Linux** and **Windows** — powered by **GTK + Cairo** and **Win32 GDI**, respectively.

> 🔧 Image composition and layout are handled at **compile-time** via a CLI tool, while rendering is performed natively at runtime using high-performance platform APIs.

## 📚 Table of Contents

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [⚙️ Setup](#️-setup)
  - [1. Generate the splash screen configuration file](#1-generate-the-splash-screen-configuration-file)
  - [2. Generate the splash screen build files](#2-generate-the-splash-screen-build-files)
  - [3. Integrate into CMake (Linux & Windows)](#3-integrate-into-cmake-linux--windows)
    - [🐧 Linux](#-linux)
    - [🪟 Windows](#-windows)
  - [4. Add the missing code on each platform](#4-add-the-missing-code-on-each-platform)
    - [🐧 Linux](#-linux-1)
    - [🪟 Windows](#-windows-1)
- [🚀 Usage](#-usage)
- [🛠️ How It Works](#️-how-it-works)
- [📝 Configuration](#-configuration)
- [📄 License](#-license)

---

## ✨ Features

- 🖼️ Native splash screens on Linux (GTK + Cairo) and Windows (WinGDI)
- 🎞️ Runtime closing animations e.g : fading
- ⚙️ CLI-driven image layout and asset generation
- 🧩 Static linking — zero runtime dependencies
- 🛠️ Easily extensible for other platforms
- 🌟 Supports raster formats like PNG and JPEG. Transparency and scaling are fully handled at compile time by the CLI.
---

## 📦 Installation

Add `native_splash_screen` to your `pubspec.yaml`:

```yaml
dependencies:
  native_splash_screen: ^0.1.0
```
Also add the CLI tool under dev_dependencies:

```yaml
dev_dependencies:
  native_splash_screen_cli: ^0.1.1
```
> 💡 Make sure both native_splash_screen and native_splash_screen_cli use the same major version to ensure compatibility between the runtime plugin and the code generator.

Then run:

```sh
flutter pub get
```

## ⚙️ Setup

Before building or running your app you should follow all these steps.

## 1. Generate the splash screen configuration file

Generate the splash screen YAML configuration file in the root directory of your project.

Run:

```sh
dart run native_splash_screen_cli init
```

This will:

- create the `native_splash_screen.yaml`

The file will have a documentation to help understand the configuration.

## 2. Generate the splash screen build files

Generate the splash screen build files (CMake files for Linux and Windows) for the platform(s).
You need to check out the file and enable or disable the platform(s).

After that run:

```sh
dart run native_splash_screen_cli setup
```
This will:

- Create the `native_splash_screen.cmake` for each desktop platform.

## 3. Integrate into CMake (Linux & Windows)

### 🐧 Linux

Apply the following patch to your `linux/runner/CMakeLists.txt`:

> if you edited the linux path in `native_splash_screen.yaml`, you
> need to apply the patch in to the **correct** CMakefile.txt 

```diff
+ # Include splash screen library configuration
+ include("${CMAKE_CURRENT_SOURCE_DIR}/native_splash_screen.cmake")

  add_executable(${BINARY_NAME}
          "main.cc"
          "my_application.cc"
          "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  )
```
### 🪟 Windows

Apply the following patch to your `windows/runner/CMakeLists.txt`:

> if you edited the windows path in `native_splash_screen.yaml`, you
> need to apply the patch in to the **correct** CMakefile.txt 

```diff
+ # Include splash screen library configuration
+ include("${CMAKE_CURRENT_SOURCE_DIR}/native_splash_screen.cmake")

  add_executable(${BINARY_NAME} WIN32
    "flutter_window.cpp"
    "main.cpp"
    "utils.cpp"
    "win32_window.cpp"
    "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
    "Runner.rc"
    "runner.exe.manifest"
  )
```

## 4. Add the missing code on each platform

### 🐧 Linux

Apply the following patch to your `linux/runner/main.cc`:

```diff
+#include <native_splash_screen_linux/native_splash_screen_linux_plugin.h>
#include "my_application.h"

int main(int argc, char** argv) {
    // Initialize GTK first
+    gtk_init(&argc, &argv);

    // So can safely show the splash screen first.
+    show_splash_screen();

    // Then initialize and run the application as normal
    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
}
```

### 🪟 Windows

Apply the following patch to your `windows/runner/main.cpp`:

```diff
+#include <native_splash_screen_windows/native_splash_screen_windows_plugin_c_api.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
   // Show the splash screen first.
+  ShowSplashScreen();

```

## 🚀 Usage

### Configuring assets

Once everything is set up, make sure to add the images path in the configuration file
and put a valid window size.

Then you can generate the splash screen code by running:

```sh
dart run native_splash_screen_cli gen
```

If everything completes successfully, you can now run and test your app.
If you encounter any issues during generation, please [open an issue](https://github.com/anicine/native_splash_screen/issues).

### Closing the splash screen

So now you need to close the splash screen in your app when you're ready:
```dart
import 'package:native_splash_screen/native_splash_screen.dart';

  @override
  void initState() {
    super.initState();
    // Close splash screen after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(animation: CloseAnimation.fade);
    });
  }

```

>💡 Calling `close()` multiple times or when the splash screen is already closed has no effect and is completely safe.

See the [example app](https://github.com/anicine/native_splash_screen/tree/main/native_splash_screen/example) for more details.

## 🛠️ How It Works

**At compile time (`gen`):**
- Parses your YAML configuration
- Composes and rasterize your image layout
- Generates native C++ source code
- Builds platform-specific static libraries

**At runtime:**
- **Linux**: Uses GTK & Cairo to render the splash screen
- **Windows**: Uses Win32 GDI for fast native rendering
- You call `close()` from Dart when your app is ready, triggering the animation

## 📝 Configuration

See [native_splash_screen_cli](https://pub.dev/packages/native_splash_screen_cli) for configuration reference.

## 📄 License

```
BSD 3-Clause License

Copyright (c) 2025, Anicine Project

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```