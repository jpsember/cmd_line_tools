#!/usr/bin/env ruby

# Runs all unit tests found in files 'test_*.rb' in specified directories, or
# current directory tree if none given

require 'js_base/test'

class RBTest

  def find_tests(argv)
    args = []
    args.concat(argv)
    args << '.' if args.empty?

    list = []
    args.each do |directory|
      directory = File.absolute_path(directory)
      output,_ = scall("find \'#{directory}\' -name \'test_*.rb\'")
      list.concat(output.split("\n"))
    end
    list
  end

  def run(argv=ARGV)

    runner = Test::Unit::AutoRunner.new

    p = Trollop::Parser.new do
      banner <<-EOS
Runs all Ruby tests found in files 'text_XXX.rb' within current directory tree
EOS
      opt :verbose,"set verbose flag"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    find_tests(argv).each do |filename|
      eval("require \"#{filename}\"")
    end

    args = []
    args << '-v' if options[:verbose]
    runner.process_args(args)
  end

end

if __FILE__ == $0
  RubyTests.new.run
end
