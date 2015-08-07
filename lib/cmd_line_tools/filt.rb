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
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse(argv)
    end

    @verbose = options[:verbose]
    @markers = options[:markers]

    parse_logfilter_file

    ARGF.each_with_index do |line,line_number|
      process_line(line,line_number)
    end
    flush_filtered
  end

  def process_line(content,line_number)
    tokenizer = Tokn::Tokenizer.new(@filter_dfa,content)
    tokenizer.accept_unknown_tokens = true
    filter_line = false
    while tokenizer.has_next
      token = tokenizer.read
      if !token.unknown?
        filter_line = true
        puts "...filtering line \##{1+line_number}, found '#{token.text}'" if @verbose
        break
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
    die "Cannot find .logfilter file" if path.nil?

    # Determine where to persist compiled file (to avoid unnecessary recompilation)
    persist_path = path + ".persist"
    if File.exist?(persist_path) && File.mtime(persist_path) < File.mtime(path)
      File.delete(persist_path)
    end
    @filter_dfa = Tokn::DFA.from_script(FileUtils.read_text_file(path),persist_path)
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
