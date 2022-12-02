require_relative 'lib/clir/data_manager/version'

Gem::Specification.new do |s|
  s.name          = "clir-data_manager"
  s.version       = Clir::DataManager::VERSION
  s.authors       = ["PhilippePerret"]
  s.email         = ["philippe.perret@yahoo.fr"]

  s.summary       = %q{Properties Manager for classes and instances}
  s.description   = %q{This gem provides usefull Classes and methods to deal with instances propreties edition and display}
  s.homepage      = "https://github.com/PhilippePerret/clir-data_manager"
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  s.metadata["allowed_push_host"] = "https://github.com/PhilippePerret/clir-data_manager"

  s.add_dependency 'clir'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-color'

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = "https://github.com/PhilippePerret/clir-data_manager"
  s.metadata["changelog_uri"] = "https://github.com/PhilippePerret/clir-data_manager/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|features)/}) }
  end
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
