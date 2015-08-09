#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/makegem'

class TestMakeGem < JSTest

  def setup
    enter_test_directory
    FileUtils.cp_r('../sample_gemproject','.')
    Dir.chdir('sample_gemproject')
    FileUtils.mv('test/_test_sample.rb','test/test_sample.rb')
  end

  def teardown
    leave_test_directory
    scall('gem uninstall js_sample')
  end

  def bury(x)
    "aaaaaaaaa\nbbbbbbbbbb s.version = #{x} ccccccccc\nddddddddddd"
  end

  def test_bump_version_number
    yes_strings =<<-EOS
      "1234.23.1234"
      "0.0.0"
      '1234.23.1234'
      '1.2.3'
    EOS

    no_strings=<<-EOS
      "1234.123."
      '0.32.1x2"
      '123.23x3.23y21'
    EOS

    yes_strings.split.each{|x| assert(MakeGem.bump_version_number_within(bury(x)),"failed with #{x}")}
    no_strings.split.each{|x| assert(!MakeGem.bump_version_number_within(bury(x)),"failed with #{x}")}
  end

  def test_makegem
    scall('makegem')
    output,_ = scall('js_sample')
    assert_equal('Hello',output.chomp)
  end

  def test_makegem_nonexistent_dir
    output,success = scall('makegem garp',false)
    assert(!success)
    assert(output.include? 'o project found')
  end

end
