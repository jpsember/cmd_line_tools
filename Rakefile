require 'rake/testtask'
require 'js_base'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = false
end

DFA_SOURCE = "lib/cmd_line_tools/json_tokens.txt"
DFA_OUTPUT = "lib/cmd_line_tools/json_tokens.dfa"

task :dfa => [DFA_OUTPUT]

file DFA_OUTPUT => DFA_SOURCE do
  puts "Compiling tokens #{DFA_SOURCE}"
  scall "tokncompile < #{DFA_SOURCE} > #{DFA_OUTPUT}"
end
