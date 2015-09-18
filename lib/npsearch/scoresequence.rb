require 'csv'

# Top level module / namespace.
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

      def run(sequence, opt)
        split_into_neuropeptides(sequence)
        count_np_cleavage_sites(sequence)
        count_c_terminal_glycines(sequence)
        np_similarity(sequence, opt[:usearch_path], opt[:tempdir])
        acidic_spacers(sequence)
      end

      private

      def split_into_neuropeptides(sequence)
        potential_nps = []
        results = sequence.seq.scan(/(?<=^|#{NP_CLV})(\w+?)(?=#{NP_CLV}|$)/i)
        headers = %w(di_clv_st mono_2_clv_st mono_4_clv_st mono_6_clv_st np
                     di_clv_end mono_2_clv_end mono_4_clv_end mono_6_clv_end)
        results.each { |e| potential_nps << Hash[headers.map(&:to_sym).zip(e)] }
        sequence.potential_cleaved_nps = potential_nps
      end

      def count_np_cleavage_sites(sequence)
        return if sequence.potential_cleaved_nps.length == 0
        sequence.potential_cleaved_nps.each do |e|
          count_dibasic_np_clv(sequence, e[:di_clv_end])
          count_mono_basic_np_clv(sequence, e[:mono_2_clv_end],
                                  e[:mono_4_clv_end], e[:mono_6_clv_end])
        end
      end

      def count_dibasic_np_clv(sequence, dibasic_clv)
        case dibasic_clv
        when 'KR'
          sequence.score += 0.09
        when 'RR', 'KK'
          sequence.score += 0.05
        end
      end

      def count_mono_basic_np_clv(sequence, mono_2_clv, mono_4_clv, mono_6_clv)
        return if mono_2_clv.nil? && mono_4_clv.nil? && mono_6_clv.nil?
        sequence.score += 0.02
      end

      # Counts the number of C-terminal glycines
      def count_c_terminal_glycines(sequence)
        return if sequence.potential_cleaved_nps.length == 0
        sequence.potential_cleaved_nps.each do |e|
          if e[:np] =~ /G$/ && e[:di_clv_end] == 'KR'
            sequence.score += 0.25
          elsif e[:np] =~ /G$|GK$|GR$/
            sequence.score += 0.10
          end
        end
      end

      def acidic_spacers(sequence)
        sequence.potential_cleaved_nps.each do |e|
          acidic_residue = e[:np].count('DE')
          percentage_acidic = acidic_residue / e[:np].length
          sequence.score += 0.02 if percentage_acidic > 0.5
        end
      end

      def np_similarity(sequence, temp_dir, usearch_path, results = nil)
        results = run_uclust(sequence, temp_dir, usearch_path) if results.nil?
        results.gsub!(/^[^C].*\n/, '')
        results.each_line do |c|
          cluster = c.split(/\W/)
          no_of_seq_in_cluster = cluster[2].to_i
          if no_of_seq_in_cluster > 1
            sequence.score += (0.15 * no_of_seq_in_cluster)
          end
        end
      end

      def run_uclust(sequence, temp_dir, usearch_path)
        f = Tempfile.new('uclust', temp_dir)
        fo = Tempfile.new('uclust_out', temp_dir)
        return unless write_sequence_content_to_tempfile(sequence, f)
        `#{usearch_path} -cluster_fast #{f.path} -id 0.5 -uc #{fo.path} \
         >/dev/null 2>&1`
        IO.read(fo.path)
      end

      def write_sequence_content_to_tempfile(sequence, tempfile)
        return false if sequence.potential_cleaved_nps.length == 0
        content = ''
        sequence.potential_cleaved_nps.each_with_index do |e, i|
          content += ">seq#{i}\n#{e[:np]}\n"
        end
        tempfile.write(content)
        tempfile.close
        true
      end
    end
  end
end
