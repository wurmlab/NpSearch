require 'logger'

module NpSearch
  # Extend stdlib's Logger class for custom initialization
  class Logger < Logger
    def initialize(dev, verbose = false)
      super dev
      self.level = verbose ? DEBUG : INFO
    end
  end
end
