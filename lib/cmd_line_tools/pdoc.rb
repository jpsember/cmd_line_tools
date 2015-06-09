#!/usr/bin/env ruby
#
# Run 'pandoc' tool to generate .pdfs, intuiting arguments

require 'js_base'

class PDoc

  def run(argv = ARGV)

    p = Trollop::Parser.new do
      banner <<-EOS
Run pandoc to compile markdown files to PDF or HTML

Usage: mscr <source[.md | .markdown | .pdf | .html]>
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

  def look_for_source(path_without_extension, source_extension)
    path = path_without_extension + source_extension
    path = nil if !File.file?(path)
    path
  end

  def processFile(path_argument)
    path = File.absolute_path(path_argument)
    generate_pdf = true

    # Bash autocomplete will stop at '.' before extension if
    # both source and output exist; in this case, remove '.'
    if path.end_with?('.')
      path = path.chomp('.')
    end

    extension = File.extname(path)

    if extension != ''
      if extension == '.md' || extension == '.markdown' || extension == '.pdf'
      elsif extension == '.html'
        generate_pdf = false
      else
        die("Bad extension: #{path}")
      end
      path_without_extension = path.chomp(extension)
    else
      path_without_extension = path
    end

    if extension == '.md' || extension == '.markdown'
      path_with_extension = look_for_source(path_without_extension,extension)
    else
      ['.md','.markdown'].each do |ext|
        path_with_extension = look_for_source(path_without_extension,ext)
        if !path_with_extension.nil?
          break
        end
      end
    end

    die("Can't find source file for #{path_argument}") if path_with_extension.nil?

    ext = generate_pdf ? ".pdf" : ".html"
    cmd = "pandoc #{path_with_extension} -o #{path_without_extension}#{ext}"
    scall(cmd)
  end

end

if __FILE__ == $0
  PDoc.new.run
end
