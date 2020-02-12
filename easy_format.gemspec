# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'chef_bridge'
  spec.version       = '0.1.0'
  spec.authors       = ['Alex Munoz']
  spec.email         = ['amunoz951@gmail.com']
  spec.license       = 'Apache-2.0'
  spec.summary       = 'Ruby library for ease of interfacing with chef data bags, node attributes, etc.'
  spec.homepage      = 'https://github.com/amunoz951/chef_bridge'

  spec.required_ruby_version = '>= 2.3'

  spec.files         = Dir['LICENSE', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'fileutils'
  spec.add_dependency 'json'
  spec.add_dependency 'easy_json_config'
  spec.add_dependency 'easy_format'
  spec.add_dependency 'easy_io'
end
