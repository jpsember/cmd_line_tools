#!/usr/bin/env ruby

require 'js_base'

class JS_SampleApp
  def run(args)
    puts "Hello"
  end
end

if __FILE__ == $0
  JS_SampleApp.new.run(ARGV)
end
