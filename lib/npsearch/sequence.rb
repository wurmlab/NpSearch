# Top level module / namespace.
module NpSearch
  # Adapted from GeneValidator's Query Class..
  # A class to hold sequence data
  class Sequence
    DI_NP_CLV = 'KR|KK|RR'
    MONO_NP_CLV = '[KRH]..R|[KRH]....R|[KRH]......R'

    attr_reader :id
    attr_reader :signalp
    attr_reader :seq
    attr_reader :html_seq
    attr_reader :translated_frame
    attr_accessor :score
    attr_accessor :potential_cleaved_nps

    def initialize(id, seq, signalp_output, frame = nil)
      @id                    = id
      sp_cleavage_site_idx   = signalp_output[:ymax_pos].to_i - 1
      @signalp               = seq[0..(sp_cleavage_site_idx - 1)]
      @seq                   = seq[sp_cleavage_site_idx..-1]
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
