$:.push File.expand_path("../lib", __FILE__)
require 'is_msfte_searchable/version'

Gem::Specification.new do |s|
  s.name          = 'is_msfte_searchable'
  s.version       = IsMsfteSearchable::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Ken Collins', 'Donald Ball']
  s.email         = ['ken@metaskills.net', 'donald.ball@gmail.com']
  s.homepage      = 'http://github.com/Decisiv/is_msfte_searchable/'
  s.summary       = 'ActiveRecord extensions for Microsoft SQL Server full-text index'
  s.description   = 'ActiveRecord extensions for Microsoft SQL Server full-text index'
  s.files         = `git ls-files`.split("\n") - ["is_msfte_searchable.gemspec"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.rdoc_options  = ['--charset=UTF-8']
  s.add_runtime_dependency     'activerecord',   '~> 3.2.0'
  s.add_runtime_dependency     'activesupport',  '~> 3.2.0'
  s.add_development_dependency 'rake',           '~> 0.9.2'
  s.add_development_dependency 'minitest',       '~> 2.8.1'
  s.add_development_dependency 'mocha',          '~> 0.10.5'
end
