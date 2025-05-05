#include "include/native_splash_screen_linux/native_splash_screen_linux_plugin.h"

#include <cairo.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "native_splash_screen_linux_plugin_private.h"

#define NATIVE_SPLASH_SCREEN_LINUX_PLUGIN(obj)                              \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),                                        \
                              native_splash_screen_linux_plugin_get_type(), \
                              NativeSplashScreenLinuxPlugin))

struct _NativeSplashScreenLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(NativeSplashScreenLinuxPlugin,
              native_splash_screen_linux_plugin,
              g_object_get_type())

// Called when a method call is received from Flutter.
static void native_splash_screen_linux_plugin_handle_method_call(
    NativeSplashScreenLinuxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (g_strcmp0(method, "close") == 0) {
    const gchar* effect = nullptr;

    FlValue* args = fl_method_call_get_args(method_call);

    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* effect_key = fl_value_new_string("effect");
      FlValue* effect_value = fl_value_lookup(args, effect_key);
      fl_value_unref(effect_key);

      if (effect_value != nullptr) {
        if (fl_value_get_type(effect_value) == FL_VALUE_TYPE_STRING) {
          effect = fl_value_get_string(effect_value);
        } else {
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
              "INVALID_ARGUMENT",
              "'effect' argument must be a String, but received non-String "
              "type.",
              nullptr));
          fl_method_call_respond(method_call, response, nullptr);
          return;
        }
      }
    }

    close_splash_screen(effect);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void native_splash_screen_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(native_splash_screen_linux_plugin_parent_class)
      ->dispose(object);
}

static void native_splash_screen_linux_plugin_class_init(
    NativeSplashScreenLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = native_splash_screen_linux_plugin_dispose;
}

static void native_splash_screen_linux_plugin_init(
    NativeSplashScreenLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  NativeSplashScreenLinuxPlugin* plugin =
      NATIVE_SPLASH_SCREEN_LINUX_PLUGIN(user_data);
  native_splash_screen_linux_plugin_handle_method_call(plugin, method_call);
}

void native_splash_screen_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  NativeSplashScreenLinuxPlugin* plugin = NATIVE_SPLASH_SCREEN_LINUX_PLUGIN(
      g_object_new(native_splash_screen_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "djeddi-yacine.github.io/native_splash_screen", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}

// Global variables to manage the splash window
static GtkWidget* splash_window = nullptr;
static gboolean splash_shown = FALSE;
static guint animation_timer_id = 0;

// Forward declarations
static gboolean on_draw_event(GtkWidget* widget,
                              cairo_t* cr,
                              gpointer user_data);
static gboolean fade_in_func(gpointer user_data);
static gboolean fade_out_func(gpointer user_data);
static gboolean slide_up_fade_func(gpointer user_data);
static gboolean slide_down_fade_func(gpointer user_data);

// Data structure for fade animation steps
struct FadeData {
  GtkWidget* window;
  int current_step;
  int total_steps;
};

// Data structure for slide-fade animation
struct SlideFadeData {
  GtkWidget* window;
  int current_step;
  int total_steps;
  int start_y;
  int move_distance;
};

// Function to clean up animation timer if it exists
static void cleanup_animation_timer() {
  if (animation_timer_id > 0) {
    g_source_remove(animation_timer_id);
    animation_timer_id = 0;
  }
}

// Function to create and show the splash screen
void show_splash_screen() {
  if (splash_shown) {
    return;  // Prevent showing multiple splash screens
  }

  // Make sure GTK is initialized
  if (!gtk_init_check(nullptr, nullptr)) {
    g_warning("Failed to initialize GTK, cannot show splash screen");
    return;
  }

  // Create the splash window
  splash_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(splash_window), native_splash_screen_title);

  // Make it behave like a splash screen
  gtk_window_set_decorated(GTK_WINDOW(splash_window),
                           FALSE);  // No borders or title bar
  gtk_window_set_resizable(GTK_WINDOW(splash_window), FALSE);
  gtk_window_set_skip_taskbar_hint(GTK_WINDOW(splash_window), TRUE);
  gtk_window_set_skip_pager_hint(GTK_WINDOW(splash_window), TRUE);
  gtk_window_set_type_hint(GTK_WINDOW(splash_window),
                           GDK_WINDOW_TYPE_HINT_SPLASHSCREEN);
  gtk_window_set_keep_above(GTK_WINDOW(splash_window), TRUE);  // Stay on top
  gtk_window_set_position(GTK_WINDOW(splash_window), GTK_WIN_POS_CENTER);
  gtk_window_set_default_size(GTK_WINDOW(splash_window),
                              native_splash_screen_width,
                              native_splash_screen_height);
  gtk_widget_set_app_paintable(splash_window, TRUE);

  // Set up for transparency
  GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(splash_window));
  GdkVisual* visual = gdk_screen_get_rgba_visual(screen);
  if (visual != nullptr && gdk_screen_is_composited(screen)) {
    gtk_widget_set_visual(splash_window, visual);
  }

  // Create a drawing area for the splash content
  GtkWidget* drawing_area = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(splash_window), drawing_area);

  // Connect the draw signal to handle background color and image drawing
  g_signal_connect(G_OBJECT(drawing_area), "draw", G_CALLBACK(on_draw_event),
                   nullptr);

  // Connect destroy signal
  g_signal_connect(G_OBJECT(splash_window), "destroy",
                   G_CALLBACK(gtk_widget_destroyed), &splash_window);

  // Set initial opacity if animation is enabled
  if (native_splash_screen_with_animation) {
    gtk_widget_set_opacity(splash_window, 0.0);
  }

  // Show all widgets
  gtk_widget_show_all(splash_window);

  // Handle fade-in animation if enabled
  if (native_splash_screen_with_animation) {
    // Fade in using 10 steps with 15ms delay between each step (~150ms total)
    const int fade_steps = 10;
    const int fade_delay_ms = 15;

    // Set up the animation data
    struct FadeData* fade_data = g_new(struct FadeData, 1);
    fade_data->window = splash_window;
    fade_data->current_step = 0;
    fade_data->total_steps = fade_steps;

    // Start the animation timer
    animation_timer_id = g_timeout_add(fade_delay_ms, fade_in_func, fade_data);
  }

  // Process events to ensure the window is displayed
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }

  splash_shown = TRUE;
}

// Function to close the splash screen
void close_splash_screen(const gchar* effect) {
  if (!splash_shown) {
    return;
  }

  // If effect is nullptr or empty
  if (effect == nullptr || *effect == '\0') {
    close_splash_window_without_animation();
  } else if (g_strcmp0(effect, "fade") == 0) {
    close_splash_window_with_fade();
  } else if (g_strcmp0(effect, "slide_up_fade") == 0) {
    close_splash_window_slide_up_fade();
  } else if (g_strcmp0(effect, "slide_down_fade") == 0) {
    close_splash_window_slide_down_fade();
  } else {
    close_splash_window_without_animation();
  }
}

// Close immediately without animation
void close_splash_window_without_animation() {
  if (!splash_shown) {
    return;
  }

  // Cancel any ongoing animation
  cleanup_animation_timer();

  // Destroy window
  if (splash_window) {
    gtk_widget_destroy(splash_window);
    splash_window = nullptr;
  }

  splash_shown = FALSE;
}

// Close with fade out animation
void close_splash_window_with_fade() {
  if (!splash_window) {
    return;
  }

  // Cancel any ongoing animation
  cleanup_animation_timer();

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;

  // Set up the animation data
  struct FadeData* fade_data = g_new(struct FadeData, 1);
  fade_data->window = splash_window;
  fade_data->current_step = 0;
  fade_data->total_steps = steps;

  // Start the animation timer
  animation_timer_id = g_timeout_add(sleep_per_step, fade_out_func, fade_data);
}

// Close with slide up and fade animation
void close_splash_window_slide_up_fade() {
  if (!splash_window) {
    return;
  }

  // Cancel any ongoing animation
  cleanup_animation_timer();

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;
  const int move_distance = 50;  // move up by 50 pixels total

  // Get current position
  gint x, y;
  gtk_window_get_position(GTK_WINDOW(splash_window), &x, &y);

  // Set up the animation data
  struct SlideFadeData* slide_data = g_new(struct SlideFadeData, 1);
  slide_data->window = splash_window;
  slide_data->current_step = 0;
  slide_data->total_steps = steps;
  slide_data->start_y = y;
  slide_data->move_distance = move_distance;

  // Start the animation timer
  animation_timer_id =
      g_timeout_add(sleep_per_step, slide_up_fade_func, slide_data);
}

// Close with slide down and fade animation
void close_splash_window_slide_down_fade() {
  if (!splash_window) {
    return;
  }

  // Cancel any ongoing animation
  cleanup_animation_timer();

  const int fade_duration_ms = 300;
  const int steps = 30;
  const int sleep_per_step = fade_duration_ms / steps;
  const int move_distance = 50;  // move down by 50 pixels total

  // Get current position
  gint x, y;
  gtk_window_get_position(GTK_WINDOW(splash_window), &x, &y);

  // Set up the animation data
  struct SlideFadeData* slide_data = g_new(struct SlideFadeData, 1);
  slide_data->window = splash_window;
  slide_data->current_step = 0;
  slide_data->total_steps = steps;
  slide_data->start_y = y;
  slide_data->move_distance = move_distance;

  // Start the animation timer
  animation_timer_id =
      g_timeout_add(sleep_per_step, slide_down_fade_func, slide_data);
}

static gboolean on_draw_event(GtkWidget* widget,
                              cairo_t* cr,
                              gpointer user_data) {
  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);

  // Get the screen
  GdkScreen* screen = gtk_widget_get_screen(widget);

  // Only fill background if compositing is NOT supported
  if (!gdk_screen_is_composited(screen)) {
    // Extract ARGB components from the background color
    double alpha =
        ((native_splash_screen_background_color >> 24) & 0xFF) / 255.0;
    double red = ((native_splash_screen_background_color >> 16) & 0xFF) / 255.0;
    double green =
        ((native_splash_screen_background_color >> 8) & 0xFF) / 255.0;
    double blue = (native_splash_screen_background_color & 0xFF) / 255.0;

    // Fill background with the specified color
    cairo_set_source_rgba(cr, red, green, blue, alpha);
    cairo_rectangle(cr, 0, 0, allocation.width, allocation.height);
    cairo_fill(cr);
  }

  // Draw the image if available
  if (native_splash_screen_image_pixels != nullptr &&
      native_splash_screen_image_width > 0 &&
      native_splash_screen_image_height > 0) {
    // Create a cairo surface from the image data
    cairo_surface_t* image_surface = cairo_image_surface_create_for_data(
        (unsigned char*)native_splash_screen_image_pixels, CAIRO_FORMAT_ARGB32,
        native_splash_screen_image_width, native_splash_screen_image_height,
        native_splash_screen_image_width * 4  // Stride
    );

    // Center the image
    int x = (allocation.width - native_splash_screen_image_width) / 2;
    int y = (allocation.height - native_splash_screen_image_height) / 2;

    // Draw the image
    cairo_set_source_surface(cr, image_surface, x, y);
    cairo_paint(cr);

    cairo_surface_destroy(image_surface);
  }

  return FALSE;  // Let GTK continue normal processing
}

static gboolean fade_in_func(gpointer user_data) {
  struct FadeData* data = (struct FadeData*)user_data;

  // Calculate new opacity
  double opacity = (double)data->current_step / data->total_steps;
  gtk_widget_set_opacity(data->window, opacity);

  // Increment step
  data->current_step++;

  // Check if animation is complete
  if (data->current_step > data->total_steps) {
    // Set final opacity to ensure we reach exactly 1.0
    gtk_widget_set_opacity(data->window, 1.0);

    // Free data and stop timer
    g_free(data);
    animation_timer_id = 0;
    return G_SOURCE_REMOVE;
  }

  // Continue the animation
  return G_SOURCE_CONTINUE;
}

// Function to handle fade-out animation steps
static gboolean fade_out_func(gpointer user_data) {
  struct FadeData* data = (struct FadeData*)user_data;

  // Calculate new opacity
  double opacity =
      (double)(data->total_steps - data->current_step) / data->total_steps;
  gtk_widget_set_opacity(data->window, opacity);

  // Increment step
  data->current_step++;

  // Check if animation is complete
  if (data->current_step > data->total_steps) {
    // Animation complete, destroy the window
    gtk_widget_destroy(data->window);
    splash_window = nullptr;
    splash_shown = FALSE;

    // Free data and stop timer
    g_free(data);
    animation_timer_id = 0;
    return G_SOURCE_REMOVE;
  }

  // Process pending events
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }

  // Continue the animation
  return G_SOURCE_CONTINUE;
}

// Function to handle slide-up-fade animation steps
static gboolean slide_up_fade_func(gpointer user_data) {
  struct SlideFadeData* data = (struct SlideFadeData*)user_data;

  // Calculate new opacity and position
  double opacity =
      (double)(data->total_steps - data->current_step) / data->total_steps;
  int y_offset = (data->move_distance * data->current_step) / data->total_steps;

  // Apply new opacity and position
  gtk_widget_set_opacity(data->window, opacity);

  // Get current x position and update window position
  gint x;
  gtk_window_get_position(GTK_WINDOW(data->window), &x, nullptr);
  gtk_window_move(GTK_WINDOW(data->window), x, data->start_y - y_offset);

  // Increment step
  data->current_step++;

  // Check if animation is complete
  if (data->current_step > data->total_steps) {
    // Animation complete, destroy the window
    gtk_widget_destroy(data->window);
    splash_window = nullptr;
    splash_shown = FALSE;

    // Free data and stop timer
    g_free(data);
    animation_timer_id = 0;
    return G_SOURCE_REMOVE;
  }

  // Process pending events
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }

  // Continue the animation
  return G_SOURCE_CONTINUE;
}

// Function to handle slide-down-fade animation steps
static gboolean slide_down_fade_func(gpointer user_data) {
  struct SlideFadeData* data = (struct SlideFadeData*)user_data;

  // Calculate new opacity and position
  double opacity =
      (double)(data->total_steps - data->current_step) / data->total_steps;
  int y_offset = (data->move_distance * data->current_step) / data->total_steps;

  // Apply new opacity and position
  gtk_widget_set_opacity(data->window, opacity);

  // Get current x position and update window position
  gint x;
  gtk_window_get_position(GTK_WINDOW(data->window), &x, nullptr);
  gtk_window_move(GTK_WINDOW(data->window), x, data->start_y + y_offset);

  // Increment step
  data->current_step++;

  // Check if animation is complete
  if (data->current_step > data->total_steps) {
    // Animation complete, destroy the window
    gtk_widget_destroy(data->window);
    splash_window = nullptr;
    splash_shown = FALSE;

    // Free data and stop timer
    g_free(data);
    animation_timer_id = 0;
    return G_SOURCE_REMOVE;
  }

  // Process pending events
  while (gtk_events_pending()) {
    gtk_main_iteration();
  }

  // Continue the animation
  return G_SOURCE_CONTINUE;
}
