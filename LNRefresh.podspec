Pod::Spec.new do |s|
  s.name     = 'LNRefresh'
  s.version  = '0.1'
  s.platform = :ios, '5.0'
  s.license  = 'MIT'
  s.summary  = 'A lightweight category of UIScrollView to implement Pull-to-fresh and Load-more. Just use 1 line code.'
  s.homepage = 'https://github.com/dskyu/LNRefresh'
  s.author   = { 'dskyu' => 'dskyu2004@gmail.com' }
  s.source   = { :git => 'https://github.com/dskyu/LNRefresh.git', :tag => '0.1' }
  s.source_files = 'LNRefresh/*.{h,m}'
  s.preserve_paths  = 'refresh'
  s.requires_arc = true
end
