#ifndef FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_

#include <cstdint>
#include <string>

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// External variables that will be set directly by the generator
extern int native_splash_screen_width;
extern int native_splash_screen_height;
extern const wchar_t* native_splash_screen_title;
extern bool native_splash_screen_with_animation;
extern const wchar_t* native_splash_screen_window_class;

// Pixel array externally defined (must be uint32_t* or uint8_t* casted)
extern const uint32_t* native_splash_screen_image_pixels;
extern int native_splash_screen_image_width;
extern int native_splash_screen_image_height;

// Function declarations for splash screen operations
FLUTTER_PLUGIN_EXPORT void ShowSplashScreen();
FLUTTER_PLUGIN_EXPORT void CloseSplashScreen(const std::string& effect);

void CloseSplashWindowWithoutAnimation();
void CloseSplashWindowWithFade();
void CloseSplashWindowSlideUpFade();
void CloseSplashWindowSlideDownFade();

// Plugin registration function
FLUTTER_PLUGIN_EXPORT void
NativeSplashScreenWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_WINDOWS_PLUGIN_C_API_H_