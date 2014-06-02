#!/usr/bin/env ruby

require 'js_base/test'

require 'cmd_line_tools/mscr'

class TestMScr <  Test::Unit::TestCase

  def setup
    enter_test_directory
    @swizzler = Swizzler.new
    @swizzler.add_meta('Dir','home'){Dir.pwd}

    $_edit_append_text = "\n# Added by swizzling\n"

    @swizzler.add('TextEditor','edit') do |path|
      c = FileUtils.read_text_file(path)
      c << $_edit_append_text
      FileUtils.write_text_file(path,c)
    end

    redirect_stdout
  end

  def teardown
    restore_stdout
    @swizzler.remove_all
    leave_test_directory
  end

  def mscr(argstr)
    MScr.new.run(argstr.split(' '))
  end

  def test_create
    mscr("foo")
    assert(File.file?('foo.rb'),'expected to find file foo.rb')
  end

  def test_illegal_extension
    assert_raises(SystemExit){mscr('foo.java')}
    assert(restore_stdout.start_with?('Bad extension'))
  end

  def test_edit_existing_without_extension
    FileUtils.write_text_file('foo','# existing file')
      mscr("foo")
    assert(File.file?('foo'),"expected to find file 'foo'")
    assert(!File.file?('foo.rb'),"did not expect 'foo.rb'")
  end

  def test_delete_new_file_if_no_changes
    $_edit_append_text = ''
    mscr("foo")
    assert(!File.file?('foo'))
    assert(!File.file?('foo.rb'))
  end

  def test_multiple_arguments
    mscr("foo foo2")
    assert(File.file?('foo.rb') && File.file?('foo2.rb'))
  end

  def test_prefer_file_with_extension
    FileUtils.write_text_file('foo','# existing file')
    FileUtils.write_text_file('foo.rb','# existing file (.rb)')

    mscr("foo")
    assert(FileUtils.read_text_file('foo.rb').end_with?($_edit_append_text))
  end

end
