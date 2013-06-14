# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastbeans/version'

Gem::Specification.new do |spec|
  spec.name          = "fastbeans"
  spec.version       = Fastbeans::VERSION
  spec.authors       = ["Dima Sabanin"]
  spec.email         = ["sdmitry@gmail.com"]
  spec.description   = %q{Tiny and fast RPC client for Ruby to call Clojure code}
  spec.summary       = %q{Ruby piece of Ruby/Clojure RPC system extracted from beanstalkapp.com}
  spec.homepage      = "https://github.com/dsabanin/fastbeans-rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "msgpack"
  spec.add_runtime_dependency "rufus-lru"
  spec.add_runtime_dependency "connection_pool"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
end
