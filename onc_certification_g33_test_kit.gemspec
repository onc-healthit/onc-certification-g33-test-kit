require_relative 'lib/onc_certification_g33_test_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'onc_certification_g33_test_kit'
  spec.version       = ONCCertificationG33TestKit::VERSION
  spec.authors       = ['Inferno Team']
  spec.summary       = 'ONC Certification (g)(33) Prior Authorization Support API Test Kit'
  spec.description   = 'ONC Certification (g)(33) Prior Authorization Support API Test Kit'
  spec.homepage      = 'https://github.com/onc-healthit/onc-certification-g33-test-kit'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'davinci_pas_test_kit', '~> 0.15', '>= 0.15.2'
  spec.add_dependency 'inferno_core', '~> 1.4', '>= 1.4.6'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.6')
  spec.metadata['inferno_test_kit'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.files         = `[ -d .git ] && git ls-files -z lib config/presets execution_scripts LICENSE`.split("\x0")

  spec.require_paths = ['lib']
end
