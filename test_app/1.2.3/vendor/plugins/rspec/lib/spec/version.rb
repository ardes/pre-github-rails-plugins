module Spec
  module VERSION
    unless defined? MAJOR
      MAJOR  = 1
      MINOR  = 0
      TINY   = 3
      RELEASE_CANDIDATE = nil

      # RANDOM_TOKEN: 0.410718983258046
      REV = "$LastChangedRevision: 2016 $".match(/LastChangedRevision: (\d+)/)[1]

      STRING = [MAJOR, MINOR, TINY].join('.')
      TAG = "REL_#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('_')}".upcase.gsub(/\.|-/, '_')
      FULL_VERSION = "#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('.')} (r#{REV})"

      NAME   = "RSpec"
      URL    = "http://rspec.rubyforge.org/"  
    
      DESCRIPTION = "#{NAME}-#{FULL_VERSION} - BDD for Ruby\n#{URL}"
    end
  end
end