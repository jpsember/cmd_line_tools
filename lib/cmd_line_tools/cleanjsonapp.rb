#!/usr/bin/env ruby

require 'js_base'
require_relative 'cleanjson'

class CleanJsonApp

  def run(argv)

    p = Trollop::Parser.new do
      opt :verbose, "verbose", :short => 'v'
      opt :dry_run, "don't write anything"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @options = options
    @verbose = options[:verbose]

    # Process command line arguments
    if p.leftovers.empty?
      p.educate
    end

    p.leftovers.each do |source|
      process_source(source)
    end
  end

  def locate_source(source)
    # Look for files in this order:
    #
    # 1) source
    # 2) source + .json (if no extension provided)
    #
    c = []
    c << source
    ext = File.extname(source)
    c << source + ".json" if ext.length == 0

    c.each do |path|
      return path if File.exist?(path)
    end

    die("File '#{source}' not found")
  end

  def process_source(source)
    source = locate_source(source)
    input = File.read(source)

    cleaner = CleanJson.new(input)
    return if !cleaner.modified

    cleaned = cleaner.cleaned_source
    puts "...writing cleaned #{source}:\n#{cleaned}\n" if @verbose
    if !@options[:dry_run]
      FileUtils.write_text_file(source,cleaned)
    end
  end
end

if __FILE__ == $0
  begin
    CleanJsonApp.new.run(ARGV)
  rescue Exception => e
    abort("Problem with cleanjson: "+e.message)
  end
end
