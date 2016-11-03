Pod::Spec.new do |s|
  s.name             = 'EasyDataKit'
  s.version          = '0.0.2'
  s.summary          = 'Super Easy Store Fetch Update And Delete Data With SQLite.'
  s.license  = 'MIT'
  s.homepage         = 'https://github.com/hawk0620/EasyDataKit'
  s.author           = { 'Hawk' => 'lxlchenhalk@gmail.com' }
  s.source           = { :git => 'https://github.com/hawk0620/EasyDataKit.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '7.0'

  s.source_files = 'EasyDataKit/**/*.{h,m}'
  s.dependency 'FMDB'
end
