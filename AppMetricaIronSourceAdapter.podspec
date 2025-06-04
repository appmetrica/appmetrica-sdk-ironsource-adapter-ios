Pod::Spec.new do |s|
  s.name             = 'AppMetricaIronSourceAdapter'
  s.version          = '1.2.0'
  s.summary          = 'AppMetrica adapter for IronSource SDK'
  s.homepage         = 'https://appmetrica.io'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AppMetrica' => 'admin@appmetrica.io' }
  s.source           = { :git => 'https://github.com/appmetrica/appmetrica-sdk-ironsource-adapter-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.static_framework = true
  
  s.swift_version = '5.5'
  
  s.default_subspecs = 'Core'
  
  s.subspec 'Core' do |core|
    core.source_files = "#{s.name}/Sources/**/*.{swift}"
    core.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
    
    core.dependency 'AppMetricaCore', '~> 5.11'
    core.dependency 'AppMetricaCoreExtension', '~> 5.11'
    core.dependency 'IronSourceSDK', '~> 8.0'
  end

  s.test_spec 'Tests' do |test_spec|
      test_spec.source_files = 'AppMetricaIronSourceAdapter/Tests/**/*.swift'
      
      test_spec.dependency 'AppMetricaIronSourceAdapter/Core'
  end
end
