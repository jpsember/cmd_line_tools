#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/grp'

class TestGrp < JSTest

  def teardown
    FileUtils.rm('../grp_defaults.txt')
    leave_test_directory(true)
  end

  def setup
    enter_test_directory('sample_files/files')
    @swizzler = Swizzler.new
    @swizzler.add('GrepApp','defaults_path'){'../grp_defaults.txt'}
  end

  def grp(argstr)
    printf("\n\nCalling grp with args: '%s'\n\n",argstr)

    GrepApp.new.run(argstr.split(' '))
  end

  def test_txt
    TestSnapshot.new.perform do
      grp("s txt")
    end
  end

  def test_remember
    TestSnapshot.new.perform do
      grp("s txt")
      puts "Running again, without arguments"
      grp("")
      puts "Running again, with just a new pattern"
      grp("t")
    end
  end

end

