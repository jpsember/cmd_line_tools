#!/usr/bin/env ruby

require 'trollop'
require 'js_base'
require 'tokn'

class FiltApp

  FILTER_FILENAME = ".filt"

  def initialize
    @filter_dfa = nil
    @filtered_count = 0
  end

  def run(argv = nil)
    argv ||= ARGV
    p = Trollop::Parser.new do
      opt :verbose, "verbose operation"
      opt :markers, "indicate filtered lines with markers"
      opt :input, "read from file instead of stdin", :type => :string
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse(argv)
    end

    @verbose = options[:verbose]
    @markers = options[:markers]
    @input = options[:input]

    parse_logfilter_file

    if @input
      FileUtils.read_text_file(@input).split("\n").each_with_index do |line,line_number|
        process_line(line,line_number)
      end
    else
      ARGF.each_with_index do |line,line_number|
        process_line(line,line_number)
      end
    end
    flush_filtered
  end

  def process_line(content,line_number)
    filter_line = false
    if !@filter_dfa.nil?
      tokenizer = Tokn::Tokenizer.new(@filter_dfa,content)
      tokenizer.accept_unknown_tokens = true
      while tokenizer.has_next
        token = tokenizer.read
        if !token.unknown?
          filter_line = true
          puts "...filtering line \##{1+line_number}, found '#{token.text}'" if @verbose
          break
        end
      end
    end
    if filter_line
      @filtered_count += 1
    else
      flush_filtered
      puts content
    end
  end

  def flush_filtered
    return if @filtered_count == 0
    if @markers
      if @filtered_count > 3
        puts "~"
        puts "~ (#{@filtered_count-2})"
        puts "~"
      else
        @filtered_count.times do
          puts "~"
        end
      end
    end
    @filtered_count = 0
  end

  # Find .logfilter file, build DFA from it
  #
  def parse_logfilter_file
    path = logfilter_path()
    if path.nil?
      puts "*** WARNING: filt cannot find expression file #{FILTER_FILENAME}"
      return
    end

    # Determine where to persist compiled file (to avoid unnecessary recompilation)
    persist_path = path + ".compiled_dfa"
    if File.exist?(persist_path) && File.mtime(persist_path) < File.mtime(path)
      File.delete(persist_path)
    end
    script = FileUtils.read_text_file(path)
    script = precompile_token_script(script)
    @filter_dfa = Tokn::DFA.from_script(script,persist_path)
  end

  # Precompile the token script, inserting (unused) token names
  #
  def precompile_token_script(script)
    result = ''
    token_index = 0
    script.split("\n").each do |line|
      line.rstrip!
      next if line.start_with?('#')
      result << "T#{token_index}: " << line
    end
    result
  end

  # Find .logfilter file, if possible, by searching from current directory upward
  #
  def logfilter_path
    dir = File.expand_path(".")
    while true
      file = File.join(dir,FILTER_FILENAME)
      return file if File.exist?(file)
      break if dir.length < 2
      dir = File.dirname(dir)
    end
    nil
  end

end

if __FILE__ == $0
  FiltApp.new.run()
end
