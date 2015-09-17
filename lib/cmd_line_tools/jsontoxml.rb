#!/usr/bin/env ruby

require 'js_base'
require 'json'
require 'xmlsimple'
require 'tokn'

class JsonToXmlApp

  CONTENT_KEY = '?'
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
      opt :dump_tokens, "dump json tokens"
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
          puts "...writing cleaned json to #{source}:\n#{cleaned_input}\n" if @verbose
          if !@options[:dry_run]
            FileUtils.write_text_file(source+"_cleaned",cleaned_input)
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

    if @options[:dump_tokens]
      @filtered_tokens.each do |tok|
        t = tok.token
        s = "(line #{t.lineNumber}, col #{t.column})"
        s = s.ljust(19)
        s << @dfa.token_name(tok.id)
        s = s.ljust(28) << ': ' << t.text
        puts s
      end
    end

    @cursor = 0
    parse_value

    text = ""
    link = @filtered_tokens[0]
    while link
      text << link.token.text
      link = link.next_link
    end
    text
  end

  def parse_value
    if @cursor >= @filtered_tokens.length
      raise_exception("unexpected end of input")
    end
    t = @filtered_tokens[@cursor]
    if t.id == MAPOPEN
      parse_map
    elsif t.id == LISTOPEN
      parse_list
    elsif t.id == FLOAT || t.id == STRING || t.id == BOOLEAN || t.id == NULL
      read
    elsif t.id == ID
      t.add_quotes
      read
    else
      raise_exception("unexpected token",t)
    end
  end

  def parse_string
    t = read
    if t.id == ID
      t.add_quotes
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
          t.remove_from_linked_list
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
          t.remove_from_linked_list
          read
          break
        end
      else
        read(LISTCLOSE)
        break
      end
    end
  end

  def peek(match_id = nil)
    if @cursor == @filtered_tokens.length
      p = LinkedToken.eof
    else
      p = @filtered_tokens[@cursor]
    end
    if match_id.nil?
      p
    else
      p.id == match_id
    end
  end

  def raise_exception(message,linked_token = nil)
    if linked_token
      t = linked_token.token
      message << " (#{t.lineNumber},#{t.column})"
    end
    raise Tokn::TokenizerException, message
  end

  def read(exp = nil)
    ret = peek
    if ret.eof?
      raise_exception("Unexpected end of input")
    end
    if exp && exp != ret.id
      raise_exception("Unexpected token",ret)
    end
    @cursor += 1
    ret
  end

  # Tokenize json source into a linked list of LinkedTokens (preserving whitespace), and
  # store the non-whitespace tokens in a list for parsing
  #
  def tokenize_json_source(json_source)
    filtered = []
    prev_token = nil
    tokenizer = Tokn::Tokenizer.new(dfa,json_source)
    while tokenizer.has_next
      token = tokenizer.read
      linked_token = LinkedToken.new(token,prev_token)
      if token.id > 0
        filtered << linked_token
      end
      prev_token = linked_token
    end
    filtered
  end

  def dfa
    if @dfa.nil?
      @dfa = Tokn::DFA.from_file('lib/cmd_line_tools/json_tokens.dfa')
    end
    @dfa
  end

  class LinkedToken

    attr_accessor :prev_link, :next_link
    attr_accessor :token

    def initialize(token, prev=nil)
      self.token = token
      self.prev_link = prev
      if prev
        follow = prev.next_link
        prev.next_link = self
        self.next_link = follow
        if follow
          follow.prev_link = prev
        end
      end
      @prev = nil
      @next = nil
    end

    @@eof_token = Tokn::Token.new(-1,nil,-1,-1)
    @@eof = LinkedToken.new(@@eof_token)

     def self.eof
      @@eof
    end

    def id
      self.token.id
    end

    def eof?
      self.token == @@eof_token
    end

    def remove_from_linked_list
      p = self.prev_link
      n = self.next_link
      if p
        p.next_link = n
      end
      if n
        n.prev_link = p
      end
    end

    def add_quotes
      tk = self.token
      self.token = Tokn::Token.new(STRING,"\"#{tk.text}\"",tk.lineNumber,tk.column)
    end

  end

end

if __FILE__ == $0
  JsonToXmlApp.new.run(ARGV)
end
