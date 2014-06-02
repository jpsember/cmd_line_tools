#!/usr/bin/env ruby
#
# Create a ruby script file

require 'js_base'
require 'js_base/pretty'
require 'js_base/text_editor'

class MScr

  def run(argv = ARGV)

    p = Trollop::Parser.new do
      banner <<-EOS
Creates or edits a ruby script, one that is executable from the command line.
If there exists a file .mscr in your home directory, it will be used to form
the script's initial contents.

Usage: mscr <scriptname[.rb]> ...
EOS
    end

    Trollop::with_standard_exception_handling p do
      raise Trollop::HelpNeeded if argv.empty?
      p.parse argv
    end

    p.educate if argv.empty?

    argv.each do |a|
      processFile(a)
    end

  end


  private


  def createFile(destPath)
    # Determine initial contents of file.  If there's a .mscr in the user's home directory,
    # read it from there.

    default_contents =<<-EOS
#!/usr/bin/env ruby

require 'js_base'

EOS

    contents = FileUtils.read_text_file(File.join(Dir.home,'.mscr'),default_contents)
    contents << "# Ruby script:  #{File.basename(destPath)}\n\n"
    FileUtils.write_text_file(destPath,contents)
    contents
  end

  def processFile(path_argument)
    path = File.absolute_path(path_argument)

    extension = File.extname(path)
    if extension != ''
      die("Bad extension: #{path}") if extension != '.rb'
      path_without_extension = path.chomp(extension)
    else
      path_without_extension = path
    end
    path_with_extension = path_without_extension + '.rb'

    add_extension = File.file?(path_with_extension) || !File.file?(path_without_extension)

    destPath = add_extension ? path_with_extension : path_without_extension
    existing = File.file?(destPath)
    previousContents = nil
    if !existing
      previousContents = createFile(destPath)
    end

    # Call the user's editor
    editor = TextEditor.new
    editor.edit(destPath)

    # If file was just created, and user made no changes, delete it
    if !existing && FileUtils.read_text_file(destPath) == previousContents
      File.delete(destPath)
    else
      # Make the script executable
      FileUtils.chmod("u+x", destPath)
    end
  end

end

if __FILE__ == $0
  Script.new.run
end
