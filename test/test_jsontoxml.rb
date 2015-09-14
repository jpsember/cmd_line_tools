#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/jsontoxml'

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

  # Haven't found a json parser that accepts both extra commas AND comments
  def OMIT_test_sloppy_json_to_xml
    TestSnapshot.new.perform do
      JsonToXmlApp.new.run("../sample_files/json/sample_extra_commas.json -o output.xml".split)
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

end
