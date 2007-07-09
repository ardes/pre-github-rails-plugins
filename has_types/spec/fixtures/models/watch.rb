class Watch < Product
  self.load_order ||= []
  self.load_order << 'Watch'
end