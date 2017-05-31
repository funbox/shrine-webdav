lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'shrine-webdav'
  spec.version       = '0.1.0'
  spec.authors       = ['Ivan Kushmantsev']
  spec.email         = ['i.kushmantsev@fun-box.ru']

  spec.summary       = 'Provides a simple WebDAV storage for Shrine.'
  spec.description   = 'Provides a simple WebDAV storage for Shrine.'
  spec.homepage      = 'https://github.com/funbox/shrine-webdav'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'shrine', '>= 2.0'
  spec.add_dependency 'http', '~> 2.2', '>= 2.2.2'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock'
end
