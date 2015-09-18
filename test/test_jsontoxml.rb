#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/jsontoxml'
require 'cmd_line_tools/cleanjsonapp'

class TestJsontoxml < JSTest

  def setup
    enter_test_directory
  end

  def teardown
    leave_test_directory
  end

  def test_json_to_xml
    TestSnapshot.new.perform do
      JsonToXmlApp.new.run("../sample_files/json/sample.json -o output.xml".split)
      puts FileUtils.read_text_file("output.xml")
    end
  end

  def test_json2_to_xml
    TestSnapshot.new.perform do
      JsonToXmlApp.new.run("../sample_files/json/sample2.json -o output.xml".split)
      puts FileUtils.read_text_file("output.xml")
    end
  end

  def test_json_with_comments_to_xml
    TestSnapshot.new.perform do
      JsonToXmlApp.new.run("../sample_files/json/comments.json -o output.xml".split)
      puts FileUtils.read_text_file("output.xml")
    end
  end

  def test_xml_to_json
    TestSnapshot.new.perform() do
      JsonToXmlApp.new.run("../sample_files/xml/sample.xml -o output.json -x".split)
      puts FileUtils.read_text_file("output.json")
    end
  end

  def test_xml3_to_json
    TestSnapshot.new.perform() do
      JsonToXmlApp.new.run("../sample_files/xml/sample3.xml -o output.json -x".split)
      puts FileUtils.read_text_file("output.json")
    end
  end

  def test_xml5_to_json
    TestSnapshot.new.perform() do
      JsonToXmlApp.new.run("../sample_files/xml/sample5.xml -o output.json -x -v".split)
      puts FileUtils.read_text_file("output.json")
    end
  end

  def process_sloppy(basename)
    TestSnapshot.new.perform() do
      path = "../sample_files/json_sloppy/#{basename}"
      FileUtils.copy(path,".")
      JsonToXmlApp.new.run("#{basename} -c -v".split)
    end
  end

  def test_json_sloppy1
    process_sloppy("1.json")
  end

  def test_json_sloppy2
    process_sloppy("2.json")
  end

  def test_json_sloppy3
    process_sloppy("3_toxml.json")
  end

  def test_missing_commas
    process_sloppy("missing_commas.json")
  end

  def test_locate_source_from_xml
    JsonToXmlApp.new.run("../sample_files/xml/sample5 -x -d".split)
  end

  def test_locate_source_to_xml
    JsonToXmlApp.new.run("../sample_files/json_sloppy/2 -d".split)
  end
  def test_locate_source_to_xml_2
    JsonToXmlApp.new.run("../sample_files/json_sloppy/3 -d".split)
  end
  def test_locate_source_to_xml_3
    JsonToXmlApp.new.run("../sample_files/json_sloppy/3_toxml -d".split)
  end
  def test_locate_source_to_xml_4
    JsonToXmlApp.new.run("../sample_files/json_sloppy/3.json -d".split)
  end
  def test_locate_source_to_xml_5
    JsonToXmlApp.new.run("../sample_files/json_sloppy/3_toxml.json -d".split)
  end

  def test_json_string_tokenizer
    [
      # Legal json strings

      '','abcd','\uABCD','\\/',

      # Illegal json strings

      '!\uabc',"!\\\u001f",'!\\',

    ].each do |str|
      legal = true
      if str.start_with? '!'
        legal = false
        str = str[1..-1]
      end
      json_expr = "[\"#{str}\"]"
      succeeded = false
      begin
        path = '_expr_.json'
        FileUtils.write_text_file(path,json_expr)
        CleanJsonApp.new.run("#{path} -dv".split)
        succeeded = true
      rescue Exception => e
      end
      assert(succeeded == legal, "result with #{json_expr} unexpected")
    end
  end

end
