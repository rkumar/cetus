# coding: utf-8

# lib = File.expand_path('../lib', __FILE__)
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'cetus'
  spec.version       = '0.2.0'
  spec.authors       = ['Rahul Kumar']
  spec.email         = ['oneness.univ@gmail.com']
  spec.description   = %q{lightning fast file navigator}
  spec.summary       = %q{lightning fast file navigator - ruby 1.9.3 .. ruby 2.6}
  spec.homepage      = 'http://github.com/rkumar/cetus'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  # http://bundler.io/blog/2015/03/20/moving-bins-to-exe.html
  # TODO change to exe as per above

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
