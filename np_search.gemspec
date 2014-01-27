# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'np_search/version'

Gem::Specification.new do |spec|
  spec.name          = "np_search"
  spec.version       = NpSearch::VERSION
  spec.authors       = ["IsmailM"]
  spec.email         = ["ismail.moghul@gmail.com"]
  spec.description   = %q{Search for Neuropeptides based solely on the common neuropeptide markers (e.g. signal peptide, dibasic cleavage sites etc.) i.e. not based on homology to known neuropeptides.}
  spec.summary       = %q{Search for Neuropeptides based on the common neuropeptides markers}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_dependency "bio", "~> 1.4"
  spec.add_dependency "haml", "~> 4"
  

end

