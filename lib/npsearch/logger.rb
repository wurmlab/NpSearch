require 'logger'

module NpSearch
  # Extend stdlib's Logger class for custom initialization and log format.
  class Logger < Logger
    def initialize(dev, verbose = false)
      super dev
      self.level     = verbose ? DEBUG : INFO
      self.formatter = proc { |_, datetime, _, msg| "#{datetime}: #{msg}\n" }
    end
  end
end
