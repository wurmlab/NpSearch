# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'npsearch/version'

Gem::Specification.new do |s|
  s.name          = 'npsearch'
  s.version       = NpSearch::VERSION
  s.authors       = ['Ismail Moghul', 'Matthew Rowe', 'Anurag Priyam',
                     'Maurice Elphick', 'Yannick Wurm']
  s.email         = ['y.wurm@qmul.ac.uk']
  s.description   = 'Search for Neuropeptides based solely on the common' \
                    ' neuropeptide markers (e.g. signal peptide, dibasic' \
                    ' cleavage sites etc.) i.e. not based on homology to' \
                    " known neuropeptides.\n\n" \
                    ' For more information: https://github.com/wurmlab/npsearch'
  s.summary       = 'Search for neuropeptides based on the common' \
                    ' neuropeptides markers'
  s.homepage      = 'https://github.com/IsmailM/NeuroPeptideSearch'
  s.license       = 'AGPL'

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.0.0'
  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~>10.3'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'minitest', '~> 5.4'

  s.add_dependency 'bio', '~> 1.4'
  s.add_dependency 'slim', '~> 3.0'
end
