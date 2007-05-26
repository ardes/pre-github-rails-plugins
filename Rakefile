task :cruise do
  failed = []
  targets = FileList['test_app/*'].exclude {|f| !File.directory?(f) }
  
  targets.reverse.each do |target|
    puts "\n\n= TARGET: #{File.basename(target).upcase}\n"
    sh("cd #{target}; rake cruise") do |ok, _|
      failed << target unless ok
    end
  end
  
  raise "\n==\nThe following targets failed: #{failed.join(', ')}" if failed.size > 0
end
