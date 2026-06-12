#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint enhanced_platform_menu.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'enhanced_platform_menu'
  s.version          = '0.3.1'
  s.summary          = 'An enhanced drop-in replacement for Flutter’s Platform Menu API.'
  s.description      = <<-DESC
An enhanced drop-in replacement for Flutter’s Platform Menu API with support for
checked items and icons on macOS and iPadOS.
                       DESC
  s.homepage         = 'https://github.com/tstumpSC/enhanced_platform_menu'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'tstumpSC' => 'tim.stump@worksheetcrafter.com' }
  s.source           = { :path => '.' }
  s.source_files = 'enhanced_platform_menu/Sources/enhanced_platform_menu/**/*.swift'
  s.resource_bundles = {'enhanced_platform_menu_privacy' => ['enhanced_platform_menu/Sources/enhanced_platform_menu/PrivacyInfo.xcprivacy']}
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
