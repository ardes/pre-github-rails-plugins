#require 'rake/clobber'

verbose(false)

task :cruise do
  failed = []
  targets = FileList['test_app/*'].exclude {|f| !File.directory?(f) }
  
  puts "#{'#'*79}\n### ci report: http://svn.ardes.com/rails_plugins r#{svn_revision}\n#{'#'*79}\n"
  
  targets.reverse.each do |target|
    rev = piston_revision("#{target}/vendor/rails")
    puts "\n\n#{'*'*79}\n** Against: rails #{File.basename(target).upcase} #{rev ? "r#{rev}" : ""}\n#{'*'*79}\n"
    sh("cd #{target}; rake -s cruise") do |ok, _|
      failed << target unless ok
    end
  end
  
  if failed.size > 0
    raise "#{'#'*79}\n### targets FAILED: #{failed.join(', ')}\n#{'#'*79}\n" 
  else
    puts "#{'#'*79}\n### build successful\n#{'#'*79}\n"
  end
end

directory 'doc'

desc 'builds the documentation for all plugins in test_app/ede and the ci report'
file 'doc' do
  sh "rake -s cruise > doc/ci_report.txt"
  targets = FileList["test_app/edge/vendor/plugins/*"].exclude('test_app/edge/vendor/plugins/*spec*')
  targets.each do |target|
    sh "cd #{target}; rake doc:all" do |ok, _|
      cp_r "#{target}/doc", "doc/#{File.basename(target)}" if ok
    end
  end
end

namespace :doc do
  desc 'updates via subversion and invokes doc:build if a new revision is detected'
  task :update => :doc do
    rev = svn_revision
    `svn update`
    `rm_rf doc; rake doc` if rev < svn_revision
  end
end

def svn_revision(path = '.')
  `svn info #{path} 2>&1` =~ /Revision: (\d{1,6})/
  $1
end

def piston_revision(path = '.')
  `svn pl -v #{path} 2>&1` =~ /piston:remote-revision : (\d{1,6})/
  $1
end