# load gems from vendor/gems/ruby and vendor/gems/-this-arch-
gems = (Dir["#{RAILS_ROOT}/vendor/gems/ruby/**"] + Dir["#{RAILS_ROOT}/vendor/gems/#{Config::CONFIG['host']}/**"]).map do |dir|
  File.directory?(lib = "#{dir}/lib") ? lib : dir
end

if gems.any?
  gems.each do |dir|
    dir = File.expand_path(dir)
    $LOAD_PATH.unshift(dir) 
    Dependencies.load_paths << dir
    Dependencies.load_once_paths << dir
  end
end