#!/usr/bin/env ruby

require 'js_base'
require 'json'
require 'tokn'

class CleanJson

  attr_reader :cleaned_source
  attr_reader :modified

  def initialize(json_source)
    @filtered_tokens = tokenize_json_source(json_source)
    @cursor = 0
    @cleaned_tokens = []
    @modified = false

    parse_value

    text = ""
    @cleaned_tokens.each do |t|
      text << t.text
    end
    @cleaned_source = text
  end

  @@dfa = nil

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
        if !peek(MAPCLOSE) && !peek(LISTCLOSE)
          # Assume he's missing a comma
          insert_missing(COMMA,',')
        else
          read(MAPCLOSE)
          break
        end
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
        if !peek(LISTCLOSE) && !peek(MAPCLOSE)
          # Assume he's missing a comma
          insert_missing(COMMA,',')
        else
          read(LISTCLOSE)
          break
        end
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
    @modified = true
    stack = pop_to_non_whitespace
    stack.pop
    push_stacked_tokens(stack)
  end

  def insert_missing(id,text)
    @modified = true
    stack = pop_to_non_whitespace
    last_token = stack.pop
    stack << Tokn::Token.new(id,text,-1,-1)
    stack << last_token
    push_stacked_tokens(stack)
  end

  def add_quotes_to_last
    @modified = true
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
      raise_exception("Unexpected token",token)
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

  DFA_SCRIPT=<<-'EOS'
# Whitespace including comments of form  # ....,   // ....,   /* .... */
WS: (   [\x00-\x20]+     |  \
        (//|\#) [\x00-\x7f^\n]*   |  \
        /\* ( \**[\x00-\x7f^/\*] |  [\x00-\x7f^\*] )* \*+ /  )+
COMMA: ,
COLON: :
LISTOPEN: \[
LISTCLOSE: \]
MAPOPEN: \{
MAPCLOSE: \}
ID:   \w[\w\d]*
FLOAT: [\+\-]?  (\d*\.\d+([eE][\+\-]?\d+)?|\d+)
STRING: " ( [^\x00-\x1f"\\] | \\["\\/bfnrt] | \\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]  )* "
BOOLEAN: (true|false)
NULL: null
EOS

  def dfa
    if @@dfa.nil?
      @@dfa = Tokn::DFA.from_script(DFA_SCRIPT,File.join(Dir.home,'.cleanjson_dfa_1'))
    end
    @@dfa
  end

end
