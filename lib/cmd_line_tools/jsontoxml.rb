#!/usr/bin/env ruby

require 'js_base'
require 'json'
require 'xmlsimple'

class JsonToXmlApp


  def run(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

      Example:
        jsontoxml alpha
      Converts file "alpha.json" to "alpha.xml"

      jsontoxml -x alpha
      Converts file "alpha.xml" to "alpha.json"

      EOS
      opt :verbose, "verbose", :short => 'v'
      opt :fromxml, "convert xml -> json", :short => 'x'
      opt :output, "output file", :type => :string
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @verbose = options[:verbose]
    @output = options[:output]

    # Process command line arguments
    if p.leftovers.empty?
      p.educate
    end

    p.leftovers.each do |source|
      process_source(source,options)
    end
  end

  def parse_json(text)
    JSON.parse(text)
  end

  def parse_xml(text)
    XmlSimple.xml_in(text)
  end

  def encode_xml(hash)
    XmlSimple.xml_out(hash)
  end

  def process_source(source,options)
    ext = File.extname(source)
    if ext.length == 0
      source = source + ".json"
    end
    if !File.exist?(source)
      die("File '#{source}' not found")
    end

    input = File.read(source)
    if !options[:fromxml]

      hash = parse_json(input)

      if @verbose
        puts "Parsed as JSON:"
        puts "----------------------------------------------------"
        puts JSON.pretty_generate(hash)
        puts
      end
      xml = encode_xml(hash)

      if @verbose
        puts "Converted to XML:"
        puts "----------------------------------------------------"
        puts xml
        puts
      end
      if @output.nil?
        target = change_extension(source,'xml')
      else
        target = @output
        target = add_extension(target,'xml') if File.extname(target) == ''
      end
      FileUtils.write_text_file(target,xml)
    else
      hash = parse_xml(input)
      if @verbose
        puts "Parsed from XML:"
        puts "----------------------------------------------------"
        puts JSON.pretty_generate(hash)
        puts
      end
      if @output.nil?
        target = change_extension(source,'json')
      else
        target = @output
        target = add_extension(target,'json') if File.extname(target) == ''
      end
      FileUtils.write_text_file(target,JSON.pretty_generate(hash))
    end

  end

end

if __FILE__ == $0
  JsonToXmlApp.new.run(ARGV)
end
