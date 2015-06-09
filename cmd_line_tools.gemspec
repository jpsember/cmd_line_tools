require 'rake'

Gem::Specification.new do |s|
  s.name        = 'cmd_line_tools'
  s.version     = '1.0.0'
  s.summary     = "Jeff's Ruby command line tools"
  s.description = "More to come"
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.executables << 'fnd' << 'grp' << 'rbtest' << 'mscr' << 'makegem' << 'cleanxcode' << 'pdoc'
  s.add_dependency('js_base')
  s.homepage = 'http://www.cs.ubc.ca/~jpsember'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end

