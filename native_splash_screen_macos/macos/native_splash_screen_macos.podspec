#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_splash_screen_macos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_splash_screen_macos'
  s.version          = '0.0.1'
  s.summary          = 'MacOS implementation of the native_splash_screen plugin.'
  s.description      = <<-DESC
MacOS implementation of the native_splash_screen plugin.
                       DESC
  s.homepage         = 'https://github.com/anicine/native_splash_screen'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anicine Project' => 'yacine2700dj@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
