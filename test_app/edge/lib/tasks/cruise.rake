task :cruise do 
  ENV['RAILS_ENV'] = 'test'
  targets = FileList["#{RAILS_ROOT}/vendor/plugins/*"].exclude('vendor/plugins/*spec*')
  failed = []
  targets.each do |target|
    if FileList["#{target}/spec/**/*_spec.rb"].size > 0
      target_name = File.basename(target)
      puts "\n#{'='*60}\n= Plugin: #{target_name}\n#{'='*60}\n"
      sh("cd #{target}; rake cruise") do |ok,_|
        failed << target_name unless ok
      end
    end
  end
  raise "\n=\n= The following plugins FAILED: #{failed.join(', ')}\n=" if failed.size > 0
end
