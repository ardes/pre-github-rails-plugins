task :cruise do 
  ENV['RAILS_ENV'] = 'test'
  Rake::Task["plugins:rcov:verify"].invoke
end
