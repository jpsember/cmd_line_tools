#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/filt'

class TestFilt < JSTest

  # File defining filter expressions
  #
  SAMPLE_FILTER =<<-eos.gsub(/^\s+/, '')
  # This is a sample token definition file
  #
  frog
  eos

  # File to be passed through the filter
  #
  SAMPLE_TEXT =<<-eos.gsub(/^\s+/, '')
  sheep
  cowmoosefrogdog
  giraffe
  eos

  TEXT_FILENAME = 'text.txt'

  def setup
    enter_test_directory
    FileUtils.write_text_file(".filt",SAMPLE_FILTER)
    FileUtils.write_text_file(TEXT_FILENAME,SAMPLE_TEXT)
  end

  def teardown
    leave_test_directory
  end

  def test_filt
    TestSnapshot.new.perform do
      FiltApp.new.run("-i #{TEXT_FILENAME}".split)
    end
  end

end
