#!/usr/bin/env ruby

require 'js_base'

class MakeGem

  def initialize
    @gemspec_path = nil
    @project_name = nil
    @rehash_flag = false
    @options = nil
  end

  def run(argv)

    @options = parse_arguments(argv)

    if @options[:advice]
      show_advice
      return
    end

    @verbose = @options[:verbose]

    saved_directory = Dir.pwd

    begin
      dir_list = argv
      dir_list << saved_directory if dir_list.empty?
      dir_list.each do |x|
        begin
          Dir.chdir(x)
        rescue Exception
          die("No project found: #{x}")
        end
        process_project
        Dir.chdir(saved_directory)
      end
    ensure
      Dir.chdir(saved_directory)
      if @rehash_flag
        echo "Rehashing rbenv"
        scall("rbenv rehash")
      end
    end
  end


  def parse_arguments(argv)
      p = Trollop::Parser.new do
      banner <<-EOS
      Makes gem in directories given, or in current directory if none
  EOS
      opt :noinstall, "don't install locally"
      opt :doc,     "generate documentation"
      opt :undocumented, "show undocumented source elements"
      opt :verbose, "display progress"
      opt :bumpversion, "bump gem version number"
      opt :advice, "display more information about what to do with finished gem"
    end

    Trollop::with_standard_exception_handling p do
      p.parse argv
    end
  end

  def show_advice
    str =<<-EOS
    Do 'gem push xxx-xxx.gem' to push to rubygems.org
    Do 'git push origin' to push new commit to github
    EOS
    puts str
  end

  def process_project
    determine_project_name()
    remove_old_versions()

    bump_version_number if @options[:bumpversion]

    if @options[:doc]
      echo "Generating documentation"
      scall("yard doc")
    end

    echo "Building gem"
    scall("gem build #{@project_name}.gemspec")

    if @options[:undocumented] && @options[:doc]
      echo "Showing undocumented elements"
      scall("yard stats --list-undoc")
    end

    install_gem_locally if !@options[:noinstall]
  end

  # Bump the version number within a gemspec
  #
  # Returns true if version number was found and bumped
  #
  def self.bump_version_number_within(gemspec_text)
    lines = gemspec_text.lines
    found_counter = 0

    expr = /\.[0-9]+['"]/
    lines.each do |line|
      next if !(line.include?('version') && line.include?('='))
      match = line.match expr
      next if !match
      found_counter += 1
      next if found_counter != 1

      matched_string = match[0]
      match_pos = line.index(matched_string)
      last_number_start = match_pos + 1
      last_number_length = matched_string.length - 2

      number = line[last_number_start,last_number_length].to_i

      line[last_number_start,last_number_length] = (number+1).to_s
    end
    found = (found_counter == 1)
    gemspec_text.replace(lines.join) if found
    found
  end

  def bump_version_number
    text = FileUtils.read_text_file(@gemspec_path)
    die "Can't find version number" if !MakeGem.bump_version_number_within(text)
    FileUtils.write_text_file(@gemspec_path,text)
  end

  def install_gem_locally
    echo "Installing gem locally"
    scall("gem install #{@project_name}")
    @rehash_flag = true
  end

  def remove_old_versions
    f = Dir.glob("#{@project_name}-*.gem")
    f.each do |x|
      echo "Removing old gem #{x}"
      FileUtils.rm_rf(x)
    end
  end

  def determine_project_name
    suffix = '.gemspec'
    gemspecs = Dir.glob("*#{suffix}")
    die "Could not find exactly one #{suffix} in #{Dir.pwd}" if gemspecs.size != 1
    @gemspec_path = gemspecs[0]
    @project_name = @gemspec_path[0...-suffix.length]
    echo "Project #{@project_name}"
  end

  def echo(msg)
    if @verbose
      puts msg
    end
  end

end


if __FILE__ == $0
  MakeGem.new.run(ARGV)
end
