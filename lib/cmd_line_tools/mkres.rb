#!/usr/bin/env ruby

require 'js_base'
require 'fileutils'

class MkResApp

  def run(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

      Create a resource file, including the directories if necessary

      Example:  If in directory ".../x/main/java/y/z",

       > mkres foo.json

      Will create the file ".../x/main/resources/y/z/foo.json" if it doesn't already exist.

       > mkres

      Will create the directory ".../x/main/resources/y/z" if it doesn't already exist.

      EOS
      opt :verbose, "verbose", :short => 'v'
      opt :dry_run, "don't modify anything"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @options = options
    @verbose = options[:verbose]

    source_path = Dir.pwd
    subdir_stack = []
    prev_path = nil
    while true
      die "Can't find ancestor directory" if source_path == prev_path
      curr_dir = File.basename(source_path)
      prev_path = source_path
      source_path = File.dirname(source_path)
      break if curr_dir == 'java'
      subdir_stack << curr_dir
    end

    resource_path = source_path
    subdir_stack << 'resources'
    while !subdir_stack.empty?
      resource_path = File.join(resource_path,subdir_stack.pop)
    end
    if !File.directory?(resource_path)
      if options[:verbose] || options[:dry_run]
        puts "...(create directory #{resource_path})"
      end
      if !options[:dry_run]
        FileUtils.mkdir_p(resource_path)
      end
    end

    p.leftovers.each do |source|
      file_path = File.join(resource_path,source)
      next if File.exist?(file_path)
      if options[:verbose] || options[:dry_run]
        puts "...(create file #{file_path})"
      end
      next if options[:dry_run]
      FileUtils.write_text_file(file_path,'')
    end
  end

end

if __FILE__ == $0
  MkResApp.new.run(ARGV)
end
