require 'forwardable'

module NpSearch
  # A class to hold sequence data
  class Sequence
    extend Forwardable
    def_delegators NpSearch, :opt

    attr_reader :id
    attr_reader :seq
    attr_reader :signalp
    attr_reader :translated_frame
    attr_reader :orf_index
    attr_accessor :score
    attr_accessor :potential_cleaved_nps

    def initialize(id, seq, signalp_output, frame = nil, orf_index = nil)
      @id                    = id
      @seq                   = seq
      @signalp               = signalp_output
      @translated_frame      = frame
      @orf_index             = orf_index
      @score                 = 0
      @potential_cleaved_nps = nil
    end
  end
end
