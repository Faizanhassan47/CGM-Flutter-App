#
# CGM SDK Plug-in: Algorithm static library libCgmAlgo.a + MethodChannel bridging。
#
Pod::Spec.new do |s|
  s.name             = 'cgm_sdk'
  s.version          = '0.1.0'
  s.summary          = 'CGM Device communication / protocol / algorithm / local storage core'
  s.description      = <<-DESC
CGM Device communication / protocol / algorithm / local storage core（Flutter plug-in）。
                       DESC
  s.homepage         = 'https://github.com/yuukitzsche'
  s.license          = { :type => 'Proprietary', :text => 'Proprietary' }
  s.author           = { 'Linkxin' => 'dev@linkxin.local' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{swift,h,m}'
  s.public_header_files = 'Classes/CgmAlgo/*.h'
  s.vendored_libraries = 'Classes/CgmAlgo/libCgmAlgo.a'
  s.dependency 'Flutter'
  s.platform = :ios, '15.5'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-ObjC',
  }
  s.swift_version = '5.0'
end
