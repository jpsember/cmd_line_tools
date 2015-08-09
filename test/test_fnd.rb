#!/usr/bin/env ruby

require 'js_base/js_test'
require 'cmd_line_tools/fnd'

class TestFnd < JSTest

  def setup
    enter_test_directory('sample_files/files')
    @swizzler = Swizzler.new
    @swizzler.add('FindApp','defaults_path'){'../fnd_defaults.txt'}
    restart_capture
  end

  def teardown
    restore_stdout
    FileUtils.rm_f('../fnd_defaults.txt')
    leave_test_directory(true)
  end

  def restart_capture
    restore_stdout
    redirect_stdout
    @captured_output = nil
  end

  def res
    @captured_output ||= restore_stdout.chomp
  end

  def has(content)
    assert(res.include?(content),"expected results to include '#{content}':\n#{res}")
  end

  def hasnt(content)
    assert(!res.include?(content),"expected results NOT to include '#{content}':\n#{res}")
  end

  def fnd(argstr)
    restart_capture
    FindApp.new.run(argstr.split(' '))
  end

  def test_find_in_subdir
    fnd('gamma.txt')
    assert(res.end_with?('gamma.txt'))
  end

  def test_remember
    fnd 'gamma.txt'
    has 'gamma'
    fnd ''
    has 'gamma'
  end

  def test_replace_remember_with_new
    fnd 'gamma.txt'
    fnd 'alpha.txt'
    has 'alpha'
    hasnt 'gamma'
  end

  def test_forget
    fnd 'alpha.txt'
    fnd '-f'
    has 'Example'
  end

end

