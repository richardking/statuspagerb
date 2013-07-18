# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statuspage/version'

Gem::Specification.new do |spec|
  spec.name          = "statuspage"
  spec.version       = Statuspage::VERSION
  spec.authors       = ["Richard King"]
  spec.email         = ["rkingucla@ymail.com"]
  spec.description   = %q{ruby wrapper for statuspage.io api}
  spec.summary       = %q{ruby wrapper for statuspage.io api}
  spec.homepage      = "https://github.com/richardking/statuspagerb"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "httparty"
end
