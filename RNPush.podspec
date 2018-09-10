
Pod::Spec.new do |s|
  s.name             = 'RNPush'
  s.version          = '0.1.0'
  s.summary          = 'RN hot update.'

  s.homepage         = 'https://github.com/ApterKing/RNPush'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangcong' => 'wangcong@medlinker.com' }
  s.source           = { :git => 'https://github.com/ApterKing/RNPush.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'RNPush/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RNPush' => ['RNPush/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'

  s.frameworks = 'Foundation', 'UIKit'
  s.dependency 'SSZipArchive', '~> 2.1.1'

end
