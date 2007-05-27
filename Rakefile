task :cruise do
  failed = []
  targets = FileList['test_app/*'].exclude {|f| !File.directory?(f) }
  
  targets.reverse.each do |target|
    puts "\n#{'*'*80}\n***\n*** TARGET PLATFORM: rails #{File.basename(target).upcase}\n***\n#{'*'*80}"
    sh("cd #{target}; rake cruise") do |ok, _|
      failed << target unless ok
    end
  end
  
  raise "\n***\n*** The following target platforms FAILED: #{failed.join(', ')}\n***" if failed.size > 0
end
