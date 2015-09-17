require 'rake'

Gem::Specification.new do |s|
  s.name        = 'cmd_line_tools'
  s.version     = '1.1.9'
  s.summary     = "Jeff's Ruby command line tools"
  s.description = "More to come"
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'lib/**/*.dfa',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.executables << 'fnd' << 'grp' << 'mscr' << 'makegem' << 'pdoc' << 'filt' << 'jsontoxml' << 'mkres'
  s.add_runtime_dependency 'trollop'
  s.add_runtime_dependency 'js_base', '>= 1.1.0'
  s.add_runtime_dependency 'tokn', '>= 2.0.0'
  s.add_runtime_dependency 'xml-simple', '1.1.5'
  s.homepage = 'http://github.com/jpsember/cmd_line_tools'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end


