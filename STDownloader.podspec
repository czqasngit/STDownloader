
Pod::Spec.new do |s|
  s.name             = 'STDownloader'
  s.version          = '1.0.0'
  s.summary          = 'A light weight data download libiary .'


  s.description      = 'A simple and easy light weight data download libiary'

  s.homepage         = 'https://github.com/czqasngit/STDownloader'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'czqasn' => 'czqasn_6@163.com' }
  s.source           = { :git => 'https://github.com/czqasngit/STDownloader.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'STDownloader/Classes/**/*'

end
