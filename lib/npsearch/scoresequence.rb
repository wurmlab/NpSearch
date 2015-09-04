require 'csv'
require 'tempfile'

module NpSearch
  # A class to score the Sequences
  class ScoreSequence
    class << self
      DI_CLV = 'KR|RR|KK'
      MONO_NP_CLV_2 = '[KR]..R'
      MONO_NP_CLV_4 = '[KR]....R'
      MONO_NP_CLV_6 = '[KR]......R'
      NP_CLV = "(#{DI_CLV})|(#{MONO_NP_CLV_2})|(#{MONO_NP_CLV_4})|" \
               "(#{MONO_NP_CLV_6})"

      def run(sequence)
        @sequence = sequence
        split_into_neuropeptides
        count_np_cleavage_sites
        count_c_terminal_glycines
        np_similarity
        acidic_spacers
      end

      def split_into_neuropeptides
        sp_cleavage_site = @sequence.signalp[:ymax_pos].to_i
        seq = @sequence.seq[sp_cleavage_site..-1]
        potential_nps = []
        results = seq.scan(/(?<=^|#{NP_CLV})(\w+?)(?=#{NP_CLV}|$)/i)
        headers = %w(di_clv_st mono_2_clv_st mono_4_clv_st mono_6_clv_st np
                     di_clv_end mono_2_clv_end mono_4_clv_end mono_6_clv_end)
        results.each { |e| potential_nps << Hash[headers.map(&:to_sym).zip(e)] }
        @sequence.potential_cleaved_nps = potential_nps
      end

      def count_np_cleavage_sites
        @sequence.potential_cleaved_nps.each do |e|
          case e[:di_clv_end]
          when 'KR'
            @sequence.score += 0.09
          when 'RR', 'KK'
            @sequence.score += 0.05
          end
          if !e[:mono_2_clv_end].nil? || !e[:mono_4_clv_end].nil? ||
             !e[:mono_6_clv_end].nil?
            @sequence.score += 0.02
          end
        end
      end

      # Counts the number of C-terminal glycines
      def count_c_terminal_glycines
        @sequence.potential_cleaved_nps.each do |e|
          if e[:np] =~ /G$/ && e[:di_clv_end] == 'KR'
            @sequence.score += 0.25
          elsif e[:np] =~ /G$|GK$|GR$/
            @sequence.score += 0.10
          end
        end
      end

      def acidic_spacers
        @sequence.potential_cleaved_nps.each do |e|
          acidic_residue = e[:np].count('DE')
          percentage_acidic = acidic_residue / e[:np].length
          @sequence.score += 0.10 if percentage_acidic > 0.5
        end
      end

      def np_similarity
        results = run_uclust
        results.gsub!(/^[^C].*\n/, '')
        results.each_line do |c|
          cluster = c.split(/\t/)
          no_of_seq_in_cluster = cluster[3].to_i
          if no_of_seq_in_cluster > 1
            @sequence.score += (0.15 * no_of_seq_in_cluster)
          end
        end
      end

      def run_uclust
        f = Tempfile.new('uclust')
        fo = Tempfile.new('uclust_out')
        write_sequence_content_to_tempfile(f)
        `usearch -cluster_fast #{f.path} -id 0.5 -uc #{fo.path} >/dev/null 2>&1`
        IO.read(fo.path)
      ensure
        f.unlink
        fo.unlink
      end

      def write_sequence_content_to_tempfile(tempfile)
        content = ''
        @sequence.potential_cleaved_nps.each_with_index do |e, i|
          content += ">seq#{i}\n#{e[:np]}\n"
        end
        tempfile.write(content)
        tempfile.close
      end
    end
  end
end
