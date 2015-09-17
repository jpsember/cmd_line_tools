#!/usr/bin/env ruby

require 'js_base'
require 'json'
require 'xmlsimple'
require 'tokn'

class JsonToXmlApp

  CONTENT_KEY = '?'

  def run(argv)

    p = Trollop::Parser.new do
      banner <<-EOS

      Example:
        jsontoxml alpha
      Converts file "alpha_toxml.json" to "alpha.xml"

      jsontoxml -x alpha
      Converts file "alpha.xml" to "alpha_toxml.json"

      EOS
      opt :verbose, "verbose", :short => 'v'
      opt :fromxml, "convert xml -> json", :short => 'x'
      opt :output, "output file", :type => :string
      opt :dry_run, "don't write anything"
      opt :suffix, "suffix expected on json file", :default => "_toxml"
      opt :noclean, "don't clean up json"
      opt :cleanonly, "do json clean only"
    end

    options = Trollop::with_standard_exception_handling p do
      p.parse argv
    end

    @options = options
    @verbose = options[:verbose]
    @output = options[:output]

    # Process command line arguments
    if p.leftovers.empty?
      p.educate
    end

    p.leftovers.each do |source|
      process_source(source)
    end
  end

  def parse_json(text)
    JSON.parse(text)
  end

  # Parse xml to Ruby hash
  #
  def parse_xml(text)
    hash = XmlSimple.xml_in(text,'KeepRoot'=>true,'ContentKey'=>CONTENT_KEY)
    if @verbose
      puts "XmlSimple parsed as:"
      puts JSON.pretty_generate(hash)
    end

    hash2 = {}
    hash.each do |key,inner_list|
      hash2 = inner_list[0]
      hash2['!'] = key
    end
    rewrite_value_from_xml(hash2)
  end

  def locate_source(source,preferred_extension)
    basename = source
    ext = File.extname(source)
    if ext.length != 0
      basename = FileUtils.remove_extension(source)
    end
    orig_basename = basename

    suffix = @options[:suffix]
    if !@options[:fromxml]
      if !basename.end_with? suffix
        basename = basename + suffix
      end
    else
      if basename.end_with? suffix
        basename[-suffix.length..-1] = ''
      end
    end

    source = basename + '.' + preferred_extension
    if !File.exist?(source)
      source2 = orig_basename + '.' + preferred_extension
      if File.exist?(source2)
        source = source2
      else
        die("File '#{source}' not found")
      end
    end
    source
  end

  def process_source(source)
    source = locate_source(source, @options[:fromxml] ? 'xml' : 'json')
    input = File.read(source)

    if !@options[:fromxml]

      if !@options[:noclean]
        cleaned_input = clean_json_source(input)
        if cleaned_input != input
          puts "...writing cleaned #{source}:\n#{cleaned_input}\n" if @verbose
          if !@options[:dry_run]
            FileUtils.write_text_file(source,cleaned_input)
          end
          input = cleaned_input
        end
      end
      return if @options[:cleanonly]

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

      target = determine_output_path(source,@output,'xml')
      FileUtils.write_text_file(target,xml) unless @options[:dry_run]

    else

      hash = parse_xml(input)
      if @verbose
        puts "Parsed from XML:"
        puts "----------------------------------------------------"
        puts JSON.pretty_generate(hash)
        puts
      end

      target = determine_output_path(source,@output,'json')
      json_output = JSON.pretty_generate(hash) + "\n"
      FileUtils.write_text_file(target,json_output) unless @options[:dry_run]
    end

  end

  def determine_output_path(source_path,user_provided_output,preferred_extension)
    output = user_provided_output
    if output.nil?
      output = FileUtils.remove_extension(source_path)
      suffix = @options[:suffix]
      if suffix
        if preferred_extension=='xml'
          if output.end_with? suffix
            output[-suffix.length..-1] = ""
          end
        else
          output = output + suffix
        end
      end
      output = FileUtils.add_extension(output,preferred_extension)
    end
    output
  end


  # Rewrite a hash parsed from xml by XmlSimple.
  #
  # Each element has these changes made:
  #
  # 1) remove superfluous lists around values:  "key" : [ <value> ]   ===>  "key" : <value>
  # 2) put element's attributes in a map, keyed by '#'
  # 3) put root element's NAME as '!' : "NAME"
  # 4) if there are multiple children with the same name, place them in a list
  #
  def rewrite_value_from_xml(topmost_value)
    if topmost_value.is_a? Array
      array = []
      topmost_value.each do |elem|
        array << rewrite_value_from_xml(elem)
      end
      return array
    elsif !topmost_value.is_a? Hash
      return topmost_value
    end


    out = {}

    attributes = {}
    key_pairs = []
    topmost_value.each do |key,value|
      if key == '!'
        out[key] = value
      elsif value.is_a? Array
        if value.length > 1
          # Preserve value as an array (but convert its elements)
          key_pairs << [key,rewrite_value_from_xml(value)]
        else
          # Convert [x] to x'
          key_pairs << [key,rewrite_value_from_xml(value[0])]
        end
      else
        attributes[key] = rewrite_value_from_xml(value)
      end
    end
    if !attributes.empty?
      out['#'] = attributes
    end
    key_pairs.each do |key,value|
      out[key] = value
    end
    out
  end

  def encode_xml(hash)
    hash = prepare_value_for_xml(hash)
    XmlSimple.xml_out(hash,'KeepRoot'=>true,'ContentKey'=>CONTENT_KEY)
  end

  # Rewrite value to conform to what xml->json would have output with KeepRoot=true
  #
  def prepare_value_for_xml(root_value, top_level = true)
    if root_value.is_a? Hash
      root_element_name = nil
      out_hash = {}
      root_value.each do |key,value|
        if key == '#'
          value.each do |attrkey,attrvalue|
            out_hash[attrkey] = attrvalue
          end
        elsif top_level && key == '!'
          root_element_name = value
        else
          value2 = prepare_value_for_xml(value, false)
          if !value2.is_a? Array
            value2 = [value2]
          end
          out_hash[key] = value2
        end
      end
      if top_level
        outer_hash = {}
        root_element_name ||= 'UNKNOWN_ROOT_ELEMENT'
        outer_hash[root_element_name] = [ out_hash ]
        return outer_hash
      else
        return out_hash
      end
    end
    if root_value.is_a? Array
      list = []
      root_value.each do |value|
        list << prepare_value_for_xml(value,false)
      end
      return list
    end
    return root_value
  end

  def clean_json_source(json_source)
    @filtered_tokens = tokenize_json_source(json_source)
    @cursor = 0
    @cleaned_tokens = []

    parse_value

    text = ""
    @cleaned_tokens.each do |t|
      text << t.text
    end
    text
  end

  @dfa = nil
  @cursor = nil
  @filtered_tokens = nil

  WS = 0
  COMMA = 1
  COLON = 2
  LISTOPEN = 3
  LISTCLOSE = 4
  MAPOPEN = 5
  MAPCLOSE = 6
  ID = 7
  FLOAT = 8
  STRING = 9
  BOOLEAN = 10
  NULL = 11

  def parse_value
    t = peek()
    if t.id == MAPOPEN
      parse_map
    elsif t.id == LISTOPEN
      parse_list
    elsif t.id == FLOAT || t.id == STRING || t.id == BOOLEAN || t.id == NULL
      read
    elsif t.id == ID
      read
      add_quotes_to_last
    else
      raise_exception("unexpected token",t)
    end
  end

  def parse_string
    t = read
    if t.id == ID
      add_quotes_to_last
    else
      if t.id != STRING
        raise_exception("unexpected token",t)
      end
    end
  end

  def parse_map
    read(MAPOPEN)
    while true
      if peek(MAPCLOSE)
        read
        break
      end
      parse_string
      read(COLON)
      parse_value
      if peek(COMMA)
        t = read
        if peek(MAPCLOSE)
          remove_last_cleaned
          read
          break
        end
      else
        read(MAPCLOSE)
        break
      end
    end
  end

  def parse_list
    read(LISTOPEN)
    while true
      if peek(LISTCLOSE)
        read
        break
      end
      parse_value
      if peek(COMMA)
        t = read
        if peek(LISTCLOSE)
          remove_last_cleaned
          read
          break
        end
      else
        read(LISTCLOSE)
        break
      end
    end
  end

  def add_cleaned(token)
    @cleaned_tokens << token
  end

  def pop_to_non_whitespace
    stack = []
    while true
      token = @cleaned_tokens.pop
      stack << token
      break if token.id != WS
    end
    stack
  end

  def push_stacked_tokens(stack)
    while !stack.empty?
      @cleaned_tokens << stack.pop
    end
  end

  def remove_last_cleaned
    stack = pop_to_non_whitespace
    stack.pop
    push_stacked_tokens(stack)
  end

  def add_quotes_to_last
    stack = pop_to_non_whitespace
    t = stack.pop
    t = Tokn::Token.new(STRING,"\"#{t.text}\"",t.lineNumber,t.column)
    stack << t
    push_stacked_tokens(stack)
  end

  def peek(match_id = nil)
    while @cursor < @filtered_tokens.length
      token = @filtered_tokens[@cursor]
      break if @filtered_tokens[@cursor].id != WS
      add_cleaned(token)
      @cursor += 1
    end

    p = nil
    if @cursor < @filtered_tokens.length
      p = @filtered_tokens[@cursor]
    end

    if match_id.nil?
      p
    else
      read if p.nil? # Generate end of input exception
      p.id == match_id
    end
  end

  def raise_exception(message,token = nil)
    if token
      message << " (#{token.lineNumber},#{token.column})"
    end
    raise Tokn::TokenizerException, message
  end

  def read(exp = nil)
    token = peek
    if token.nil?
      raise_exception("Unexpected end of input")
    end
    if exp && exp != token.id
      raise_exception("Unexpected token",ret)
    end
    add_cleaned(token)
    @cursor += 1
    token
  end

  def tokenize_json_source(json_source)
    filtered = []
    tokenizer = Tokn::Tokenizer.new(dfa,json_source)
    while tokenizer.has_next
      filtered << tokenizer.read
    end
    filtered
  end

  def dfa
    if @dfa.nil?
      dfa_file = File.join(File.dirname(File.expand_path(__FILE__)),'json_tokens.dfa')
      @dfa = Tokn::DFA.from_file(dfa_file)
    end
    @dfa
  end

end


if __FILE__ == $0
  begin
    JsonToXmlApp.new.run(ARGV)
  rescue Exception => e
    abort("Problem with jsontoxml: "+e.message)
  end
end
