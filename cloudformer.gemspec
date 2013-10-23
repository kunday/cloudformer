# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudformer/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudformer"
  spec.version       = Cloudformer::VERSION
  spec.authors       = ["Arvind Kunday"]
  spec.email         = ["hi@kunday.com"]
  spec.description   = %q{Rake helper tasks for Cloudformation}
  spec.summary       = %q{Helper tools for aws cloudformation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_dependency "rake"
  spec.add_dependency "aws-sdk"
end
