lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nxt_registry/version"

Gem::Specification.new do |spec|
  spec.name          = "nxt_registry"
  spec.version       = NxtRegistry::VERSION
  spec.authors       = ["Andreas Robecke"]
  spec.email         = ["a.robecke@getsafe.de"]

  spec.summary       = %q{A registry}
  spec.homepage      = "https://www.robecke.de"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://www.robecke.de"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://www.robecke.de"
  spec.metadata["changelog_uri"] = "https://www.robecke.de"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
