#!/usr/bin/env ruby

require 'js_base/test'

require 'cmd_line_tools/grp'

class TestGrp <  Test::Unit::TestCase

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
    IORecorder.new('test_txt').perform do
      grp("s txt")
    end
  end

  def test_remember
    IORecorder.new.perform do
      grp("s txt")
      puts "Running again, without arguments"
      grp("")
      puts "Running again, with just a new pattern"
      grp("t")
      puts "Running again, forgetting"
      grp("-f")
    end
  end

end

