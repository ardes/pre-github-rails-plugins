# In rails 1.2, plugins aren't available in the path until they're loaded.
# Check to see if the rspec plugin is installed first and require
# it if it is.  If not, use the gem version.
rspec_base = File.expand_path(File.join (File.dirname(__FILE__), '../../vendor/plugins/rspec/lib'))
$LOAD_PATH.unshift(rspec_base) if File.exist?(rspec_base) and !$LOAD_PATH.include?(rspec_base)
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

namespace :plugins do  
  desc "Generate RCov report for all plugins"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_files  = FileList['vendor/plugins/*/spec/**/*_spec.rb'].exclude('vendor/plugins/*spec*')
    t.rcov        = true
    t.rcov_dir    = 'doc/coverage'
    include_files = FileList['vendor/plugins/*/lib'].exclude('vendor/plugins/*spec*')
    t.rcov_opts   = ['--text-report', '--include-file', include_files.join(','), '--exclude', '^app\/', '--rails']
  end

  namespace :rcov do
    desc "Verify RCov threshold for all plugins"
    RCov::VerifyTask.new(:verify => "plugins:rcov") do |t|
      t.threshold = 100.0
      t.index_html = File.join(File.dirname(__FILE__), '../../doc/coverage/index.html')
    end
  end
end