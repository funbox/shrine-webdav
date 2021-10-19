lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'shrine-webdav'
  spec.version       = '0.2.3'
  spec.authors       = ['Ivan Kushmantsev', 'Dmitry Efimov']
  spec.email         = ['i.kushmantsev@fun-box.ru', 'tuwilof@gmail.com']

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

  spec.add_dependency 'shrine', '~> 3.0'
  spec.add_dependency 'http', '>= 4.0'
  spec.add_dependency 'down', '~> 5.0'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'webmock', '~> 3'
end
