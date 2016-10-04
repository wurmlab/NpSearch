# Top level module / namespace.
module NpSearch
  # Adapted from GeneValidator's Query Class..
  # A class to hold sequence data
  class Sequence
    DI_NP_CLV   = 'KR|KK|RR'.freeze
    MONO_NP_CLV = '[KRH]..R|[KRH]....R|[KRH]......R'.freeze

    attr_reader :id
    attr_reader :defline
    attr_reader :signalp
    attr_reader :seq
    attr_reader :html_seq
    attr_reader :translated_frame
    attr_accessor :score
    attr_accessor :potential_cleaved_nps

    def initialize(entry, sp, frame = nil)
      @id                    = entry.entry_id
      @defline               = entry.definition
      sp_cleavage_site_idx   = sp[:ymax_pos].to_i - 1
      @signalp               = sp[:orf][0..(sp_cleavage_site_idx - 1)]
      @seq                   = sp[:orf][sp_cleavage_site_idx..-1]
      @html_seq              = format_seq_for_html
      @translated_frame      = frame
      @score                 = 0
      @potential_cleaved_nps = nil
    end

    def format_seq_for_html
      seq = @seq.gsub(/C/, '<span class=cysteine>C</span>')
      seq.gsub!(/#{DI_NP_CLV}/i, '<span class=np_clv>\0</span>')
      seq.gsub!(/#{MONO_NP_CLV}/i, '\0::NP_CLV::') # so that we can target 'R'
      seq.gsub!('R::NP_CLV::', '<span class=mono_np_clv>R</span>')
      seq.gsub!('G<span class=np_clv>',
                '<span class=glycine>G</span><span class=np_clv>')
      "<span class=signalp>#{@signalp}</span><span class=seq>#{seq}</span>"
    end
  end
end
