#!/usr/bin/env ruby
require 'js_base'

class CleanXCode

  def remove_directory(dir_relative_to_home)
    path = File.join(Dir.home,dir_relative_to_home)
    return if !File.directory?(path)
    puts "...removing directory #{path}"
    FileUtils.rm_rf(path)
  end

  def run(argv)


    outp,_ = scall('ps aux')

    err = false
    if /Applications\/Xcode.app\/Contents\/MacOS\/Xcode/.match(outp)
      puts "Please quit XCode."
      err = true
    end

    if /iPhoneSimulator/.match(outp)
      puts "Please quit the simulator."
      err = true
    end

    return if err

    remove_directory "Library/Application Support/iPhone Simulator"
    remove_directory "Library/Developer/Xcode/DerivedData"

  end

end

if __FILE__ == $0
  CleanXCode.new.run(ARGV)
end
