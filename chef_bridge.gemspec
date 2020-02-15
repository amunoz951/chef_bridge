# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'chef_bridge'
  spec.version       = '0.1.1'
  spec.authors       = ['Alex Munoz']
  spec.email         = ['amunoz951@gmail.com']
  spec.license       = 'Apache-2.0'
  spec.summary       = 'Ruby library for ease of interfacing with chef data bags, node attributes, etc.'
  spec.homepage      = 'https://github.com/amunoz951/chef_bridge'

  spec.required_ruby_version = '>= 2.3'

  spec.files         = Dir['LICENSE', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2'
  spec.add_dependency 'easy_json_config', '~> 0'
  spec.add_dependency 'easy_format', '~> 0'
  spec.add_dependency 'easy_io', '~> 0'
end
