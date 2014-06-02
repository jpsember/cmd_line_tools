#!/usr/bin/env ruby

# There's an underscore in this file's name to avoid it being
# found by unit test searches.  The copy's underscore is removed by the makegem unit test.
#
require 'js_base/test'

class TestSampleApp <  Test::Unit::TestCase

  def test_app
    output,success = scall('js_sample')
    assert_equal(output.chomp,"Hello")
  end

end
