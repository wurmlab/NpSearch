# Top level module / namespace.
module NpSearch
  # A class to score the Sequences
  class ScoreSequence
    class << self
      DI_CLV        = 'KR|RR|KK'.freeze
      MONO_NP_CLV_2 = '[KR]..R'.freeze
      MONO_NP_CLV_4 = '[KR]....R'.freeze
      MONO_NP_CLV_6 = '[KR]......R'.freeze
      NP_CLV = "(#{DI_CLV})|(#{MONO_NP_CLV_2})|(#{MONO_NP_CLV_4})|" \
               "(#{MONO_NP_CLV_6})".freeze

      def run(sequence, opt)
        split_into_potential_neuropeptides(sequence)
        count_np_cleavage_sites(sequence)
        count_c_terminal_glycines(sequence)
        np_similarity(sequence, opt[:temp_dir])
        acidic_spacers(sequence)
      end

      private

      def split_into_potential_neuropeptides(sequence)
        potential_nps = []
        results = sequence.seq.scan(/(?<=^|#{NP_CLV})(\w+?)(?=#{NP_CLV}|$)/i)
        headers = %w(di_clv_st mono_2_clv_st mono_4_clv_st mono_6_clv_st np
                     di_clv_end mono_2_clv_end mono_4_clv_end mono_6_clv_end)
        results.each { |e| potential_nps << Hash[headers.map(&:to_sym).zip(e)] }
        sequence.potential_cleaved_nps = potential_nps
      end

      def count_np_cleavage_sites(sequence)
        return if sequence.potential_cleaved_nps.empty?
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
        return if sequence.potential_cleaved_nps.empty?
        sequence.potential_cleaved_nps.each do |e|
          if e[:np] =~ /FG$/ && e[:di_clv_end] == 'KR'
            sequence.score += 0.40
          elsif e[:np] =~ /G$/ && e[:di_clv_end] == 'KR'
            sequence.score += 0.25
          elsif e[:np] =~ /G$|GK$|GR$/
            sequence.score += 0.10
          end
        end
      end

      # Adds 0.10 if the acidic spacer is detected.
      # Acidic Spacer is defined as being less than 25% of the precursor length
      # (not including the Signalp) && having more than 50% D and E amino acids.
      def acidic_spacers(sequence)
        sequence.potential_cleaved_nps.each do |e|
          next if e[:np].length / sequence.seq.length > 0.25
          sequence.score += 0.10 if e[:np].count('DE') / e[:np].length > 0.5
        end
      end

      def np_similarity(sequence, temp_dir)
        results  = run_cdhit(sequence, temp_dir)
        clusters = results.split(/^>Cluster \d+\n/)
        clusters.each do |c|
          next if c.nil?
          no_of_seqs_in_cluster = c.split("\n").length
          if no_of_seqs_in_cluster > 1
            sequence.score += (0.15 * no_of_seqs_in_cluster)
          end
        end
      end

      def run_cdhit(sequence, temp_dir)
        f = Tempfile.new('clust', temp_dir)
        fo = Tempfile.new('clust_out', temp_dir)
        return unless write_potential_peptides_to_tempfile(sequence, f)
        `cd-hit -c 0.5 -n 3 -l 4 -i #{f.path} -o #{fo.path}`
        IO.read("#{fo.path}.clstr")
      end

      def write_potential_peptides_to_tempfile(sequence, tempfile)
        return false if sequence.potential_cleaved_nps.empty?
        sequences = ''
        sequence.potential_cleaved_nps.each_with_index do |e, i|
          sequences += ">seq#{i}\n#{e[:np]}\n"
        end
        tempfile.write(sequences)
        tempfile.close
        true
      end
    end
  end
end
