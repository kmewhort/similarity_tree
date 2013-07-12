# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'similarity_tree/version'

Gem::Specification.new do |spec|
  spec.name          = "similarity_tree"
  spec.version       = SimilarityTree::VERSION
  spec.authors       = ["Kent Mewhort"]
  spec.email         = ["kent@openissues.ca"]
  spec.description   = %q{Generates a tree representing the branches or revisions to a set of HTML files}
  spec.summary       = %q{Generates a tree representing the branches or revisions to a set of HTML files}
  spec.homepage      = "https://github.com/kmewhort/similarity_tree/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "fast_html_diff", "~> 0.8.1"
  spec.add_runtime_dependency "gsl"
  spec.add_runtime_dependency "tf-idf-similarity"
  spec.add_runtime_dependency "ruby-progressbar"
end
