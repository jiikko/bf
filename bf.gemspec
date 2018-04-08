
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bf/version"

Gem::Specification.new do |spec|
  spec.name          = "bf"
  spec.version       = BF::VERSION
  spec.authors       = ["jiikko"]
  spec.email         = ["n905i.1214@gmail.com"]

  spec.summary       = %q{tool for bf.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/jiikko/bf"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "mysql2", ">= 0.3.18"
  spec.add_development_dependency "resque_spec"

  spec.add_dependency "activerecord", ">= 5.0"
  spec.add_dependency "resque", "< 4"
end
