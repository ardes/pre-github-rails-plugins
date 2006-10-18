module Ardes
  module ArgumentsConfiguration
    def configuration
      self.configuration = Hash.new unless self.last.is_a?(Hash)
      self.last
    end
    
    def configuration=(config)
      self.pop if self.last.is_a?(Hash)
      self.push(config)
    end
    
    def without_configuration!
      self.pop if self.last.is_a?(Hash)
      self
    end
    
    def without_configuration
      self.dup.without_configuration!
    end
    
    def apply_defaults!(*defaults)
      configuration = (defaults.last.is_a?(Hash) ? defaults.pop : {}).merge(self.configuration)
      self.without_configuration!
      (self.size...defaults.size).each {|index| self[index] = defaults[index]}
      self.configuration = configuration if configuration.size > 0
      self
    end
    
    def apply_defaults(*defaults)
      self.dup.apply_defaults!(*defaults)
    end
  end
end