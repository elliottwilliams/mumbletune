# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mumbletune/version'

Gem::Specification.new do |spec|
  spec.name          = "mumbletune"
  spec.version       = Mumbletune::VERSION
  spec.authors       = ["Elliott Williams"]
  spec.email         = ["e@elliottwillia.ms"]
  spec.description   = "Mumbletune connects to a mumble server and allows users to"\
                       " interact with and play a queue of music from Spotify."
  spec.summary       = "A Mumble VOIP bot that plays Spotify."
  spec.homepage      = "http://github.com/elliottwilliams/mumbletune"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "mumble-ruby"
  spec.add_runtime_dependency "hallon"
  spec.add_runtime_dependency "ffi", ">= 1.8"

  spec.add_runtime_dependency "daemons"
  spec.add_runtime_dependency "text"
  spec.add_runtime_dependency "mustache"
end
