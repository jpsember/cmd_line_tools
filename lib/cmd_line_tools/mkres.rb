#!/usr/bin/env ruby

require 'js_base'
require 'fileutils'

class MkResApp

  def run(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

      Create a resource file or directory.

       > mkres x/main/java/y/dir

      Will create the directory "x/main/resources/y/dir", if it doesn't already exist.

       > mkres x/main/java/y/file.ext

      Will create the file "x/main/resources/y/file.ext" if it doesn't already exist.

      EOS
      opt :verbose, "verbose", :short => 'v'
      opt :dry_run, "don't modify anything"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @options = options
    @dryrun = options[:dryrun]
    @verbose = options[:verbose] || @dryrun

    p.leftovers.each do |source|
      process_source(source)
    end
  end

  def process_source(source)

    source_dir = nil
    resource_name = nil

    file_path = File.expand_path(source)

    # If this is already a directory, just create the corresponding resource directory.
    # If it's a non-existent file within an existing directory,

    if File.directory?(file_path)
      source_dir = file_path
    else
      if File.file?(file_path)
        die "File already exists: #{file_path}"
      end
      source_dir = File.dirname(file_path)
      resource_name = File.basename(file_path)
    end
    die "directory not found: #{source_dir}" unless File.directory?(source_dir)

    resource_dir = find_resource_dir(source_dir)

    if resource_name
      file_path = File.join(resource_dir,resource_name)
      return if File.exist?(file_path)
      puts "...(create file #{file_path})" if @verbose
      FileUtils.write_text_file(file_path,'') unless @dryrun
    end

  end

  def find_resource_dir(source_path)
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
      puts "...(create directory #{resource_path})" if @verbose
      FileUtils.mkdir_p(resource_path) unless @dryrun
    end
    resource_path
  end

end

if __FILE__ == $0
  MkResApp.new.run(ARGV)
end
