require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'Voskcap'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/VoskCapPlugin/*.{swift, h}'
  s.ios.deployment_target  = '13.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'

  s.public_header_files = 'ios/Sources/VoskCapPlugin/vosk_api.h'

  # Include the Vosk framework
  s.vendored_frameworks = 'ios/Sources/Frameworks/libvosk.xcframework'
  
  # Dependencies
  s.frameworks = ['AVFoundation', 'Accelerate']
  s.libraries = 'c++'

  # Include vosk_model folder
  # s.resources = 'ios/Sources/Resources/**/*'
  # s.resource_bundles = {
  #   'Voskcap' => ['ios/Sources/Resources/**/*']
  # }
  s.resources = ['ios/Sources/Resources/**/*']


  s.info_plist = {
    'NSMicrophoneUsageDescription' => 'Requires access to the microphone for speech recognition.'
  }

  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/ios/Sources/VoskCapPlugin'
  }

end
