#!/usr/bin/env ruby

require 'js_base'

class GrepApp

  def defaults_path()
    File.join(Dir.home,".grp_defaults")
  end

  def parse_args(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

Example:
     grp velocity cpp h
         Searches for all occurrences of 'velocity' in *.cpp, *.h recursively

     grp
         Repeats the last search

EOS
      opt :pattern,"search pattern",:type=>:string
      opt :extensions,"filename extensions 'xxx/yyy/zzz...'",:type=>:string
      opt :forget,"forget saved arguments"
      opt :verbose,"verbose"
    end

    # set default values
    @linenumbers = false
    @expr = nil
    @extensions = []

    # If there's a defaults file, parse it
    #
    # It has one argument per line
    #
    @parm_file = defaults_path()

    if !argv.include?('-f') && !argv.include?('--forget')
      argv[0,0] = FileUtils.read_text_file(@parm_file,'').split("\n")
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @expr ||= options[:pattern]
    @extensions = options[:extensions].split('/') if options[:extensions]
    @verbose = options[:verbose]

    # Process command line arguments
    #
    if !p.leftovers.empty?
      @expr = p.leftovers.shift
    end
    if !p.leftovers.empty?
      @extensions = p.leftovers
    end

    if @extensions.empty?
      p.educate
    end

    t = []
    if @expr && @expr.size > 0
      t << "-p" << @expr
    end
    if @extensions.size > 0
      t << "-e" << @extensions.join('/')
    end

    FileUtils.write_text_file(@parm_file,t.join("\n")+"\n",true)
  end

  def show_result(result)
    lines = result.split("\n")

    prev_name = nil
    lines.each do |x|
      c1 = x.index(':')
      c2 = x.index(':',1+c1)
      line_num = (x[c1+1...c2]).to_i
      if line_num == 0
        puts x
        next
      end

      text = x[c2+1..-1]
      name = x[0...c1]
      if name != prev_name
        puts
        puts(name)
        prev_name = name
      end
      printf("  %4d | %s\n",line_num,text)
    end
  end

  def run(args)
    parse_args(args)

    cmd = "grep -ri"
    @extensions.each do |ext|
      cmd += " --include \"*.#{ext}\""
    end
    cmd += " -n"
    cmd += " -e #{@expr}"
    cmd += " ."
    puts cmd if @verbose

    res,succ = scall(cmd, false)
    puts "Result from shell command:\n#{res}" if @verbose
    show_result(res) if succ
  end
end

if __FILE__ == $0
  GrepApp.new.run(ARGV)
end
