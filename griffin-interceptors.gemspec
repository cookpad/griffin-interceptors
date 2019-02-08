lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'griffin/interceptors/version'

Gem::Specification.new do |spec|
  spec.name          = 'griffin-interceptors'
  spec.version       = Griffin::Interceptors::VERSION
  spec.authors       = ['Yuta Iwama']
  spec.email         = ['yuta-iwama@cookpad.com']

  spec.summary       = 'A collection of interceptors for griffin'
  spec.description   = 'A collection of interceptors for griffin'
  spec.homepage      = 'https://github.com/cookpad/griffin-interceptors'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'griffin', '>= 0.1.5'
  spec.add_dependency 'get_process_mem', '~> 0.2.3'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
