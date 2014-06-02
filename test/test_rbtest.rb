#!/usr/bin/env ruby

require 'js_base/test'

class TestRBTest <  Test::Unit::TestCase

  def setup
    enter_test_directory
    FileUtils.cp_r('../sample_tests','.')
    FileUtils.mv('sample_tests/t1.txt','sample_tests/test_1.rb')
    FileUtils.mv('sample_tests/subdir/t2.txt','sample_tests/subdir/test_2.rb')
  end

  def teardown
    leave_test_directory
  end

  def test_run_normally
    output,_ = scall('rbtest',false)
    assert(output.include? '4 tests, 4 assertions, 2 failures, 0 errors, 0 skips')
  end

  def test_run_verbosely
    output,_ = scall('rbtest -v',false)
    assert(output.include? '4 tests, 4 assertions, 2 failures, 0 errors, 0 skips')
    assert(output.include? 'Run options: -v')
  end

end
