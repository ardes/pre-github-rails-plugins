#! /usr/bin/env ruby
#
# Run rake cruise in each target path
targets = Dir[File.expand_path(File.join(File.dirname(__FILE__), '*'))].select{|f| File.directory?(f)}

success = true
targets.each do |target|
  puts "\n==\nTarget: rails #{File.basename(target)}\n"
  puts `cd #{target}; rake cruise`
  success &&= ($? == 0) # record the success of each task
end

exit(success ? 0 : 1)