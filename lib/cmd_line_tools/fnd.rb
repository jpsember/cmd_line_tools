#!/usr/bin/env ruby

require 'js_base'

class FindApp

  def defaults_path()
    File.join(Dir.home,".fnd_defaults")
  end

  def parse_args(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

Example:
     fnd alpha
         Searches for all files named 'alpha' in current directory tree

     fnd
         Repeats the last search

EOS
      opt :patterns,"files to search for (internal use only)",:type=>:string
      opt :forget,"forget saved arguments"
    end

    # set default values
    @find_expressions = []

    # If there's a defaults file, parse it
    #
    # It has one argument per line
    #
    parm_file = defaults_path()

    if !argv.include?('-f') && !argv.include?('--forget')
      argv[0,0] = FileUtils.read_text_file(parm_file,'').split("\n")
      # puts "Starting with remembered expressions: #{argv}"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    if options[:patterns]
      @find_expressions.concat(options[:patterns].split('/'))
      # puts "expressions from options: #{@find_expressions}"
    end

    # Process command line arguments
    if !p.leftovers.empty?
      @find_expressions = p.leftovers
      # puts "replacing find expr with leftovers: #{@find_expressions}"
    end

    if @find_expressions.empty?
      p.educate
    end

    t = []
    if @find_expressions.size > 0
      t << "-p" << @find_expressions.join('/')
      # puts "saving find expr in defaults file: #{t}"
    end

    FileUtils.write_text_file(parm_file,t.join("\n")+"\n",true)
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

  def filter(results)
    results.lines.reject{|x| x.include?('Permission denied')}.join.chomp
  end

  def run(args)
    parse_args(args)

    cmd = "find . -iname"
    @find_expressions.each do |ext|
      cmd += " \"#{ext}\""
    end
    res,_ = scall(cmd, false)
    puts filter(res)
  end
end

if __FILE__ == $0
  FindApp.new.run(ARGV)
end
