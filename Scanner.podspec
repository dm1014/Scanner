Pod::Spec.new do |s|
  s.name             = 'Scanner'
  s.version          = '0.1.0'
  s.summary          = 'Barcode/QR '

  s.description      = <<-DESC
Barcode/QR scanner
                       DESC

  s.homepage         = 'https://github.com/dm1014/Scanner'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'David Martin' => 'd.1014@yahoo.com' }
  s.source           = { :git => 'https://github.com/dm1014/Scanner.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'Scanner/Scanner/Scanner.swift', 'Scanner/Scanner/String+Codes.swift', 'Scanner/Scanner/Error+Additions.swift'
  s.ios.framework  = 'AVFoundation', 'UIKit'

end
