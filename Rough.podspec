#
# Be sure to run `pod lib lint Rough.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'Rough'
  s.version          = '0.1.1'
  s.summary          = 'Rough lets you draw in a sketchy, hand-drawn-like, style.'


  s.description      = <<-DESC
Rough lets you draw in a sketchy, hand-drawn-like, style. The library defines primitives to draw lines, curves, arcs, polygons, circles, and ellipses.
                       DESC

  s.homepage         = 'https://github.com/bakhtiyork/Rough'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bakhtiyor Khodjaev' => 'pods@bakhtiyor.com' }
  s.source           = { :git => 'https://github.com/bakhtiyork/Rough.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.0'

  s.source_files = 'Rough/Classes/**/*'
end
