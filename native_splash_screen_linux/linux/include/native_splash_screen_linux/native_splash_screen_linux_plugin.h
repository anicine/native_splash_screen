#ifndef FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_LINUX_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_LINUX_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _NativeSplashScreenLinuxPlugin NativeSplashScreenLinuxPlugin;
typedef struct {
  GObjectClass parent_class;
} NativeSplashScreenLinuxPluginClass;

FLUTTER_PLUGIN_EXPORT GType native_splash_screen_linux_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void
native_splash_screen_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

extern int native_splash_screen_width;
extern int native_splash_screen_height;
extern const char* native_splash_screen_title;
extern bool native_splash_screen_with_animation;

extern unsigned int native_splash_screen_background_color;  // ARGB format
extern const unsigned char*
    native_splash_screen_image_pixels;  // Raw image data in ARGB format
extern int native_splash_screen_image_width;
extern int native_splash_screen_image_height;

#ifdef __cplusplus
}
#endif

// Function declarations
FLUTTER_PLUGIN_EXPORT void show_splash_screen();
FLUTTER_PLUGIN_EXPORT void close_splash_screen(const gchar* effect);

void close_splash_window_without_animation();
void close_splash_window_with_fade();
void close_splash_window_slide_up_fade();
void close_splash_window_slide_down_fade();

G_END_DECLS

#endif  // FLUTTER_PLUGIN_NATIVE_SPLASH_SCREEN_LINUX_PLUGIN_H_
