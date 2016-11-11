require 'forwardable'
require 'open3'

# Top level module / namespace.
module NpSearch
  # A class to hold sequence data
  class Signalp
    class << self
      extend Forwardable
      def_delegators NpSearch, :opt

      def analyse_sequence(seq)
        sp_headers = %w(name cmax cmax_pos ymax ymax_pos smax smax_pos smean d
                        sp dmaxcut networks orf)
        data       = setup_analysis(seq)
        orf_results = []
<<<<<<< Updated upstream
        cmd = "echo '#{data[:fasta]}\n' | #{opt[:signalp_path]} -t euk" \
              " -f short -U 0.34 -u 0.34"
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
        sp_results = stdout.gets(nil).split("\n").delete_if { |l| l[0] == '#' }
        stdin.close; stdout.close; stderr.close
=======
        data.each do |seq|
          cmd = "echo '>seq\n#{seq}\n' | #{opt[:signalp_path]} -t euk" \
                " -f short -U 0.34 -u 0.34"


        end

        s = `echo "#{data[:fasta]}\n" | #{opt[:signalp_path]} -t euk \
             -f short -U 0.34 -u 0.34`
        sp_results = s.split("\n").delete_if { |l| l[0] == '#' }
>>>>>>> Stashed changes
        sp_results.each_with_index do |line, idx|
          line = line + ' ' + data[:seq][idx].to_s
          orf_results << Hash[sp_headers.map(&:to_sym).zip(line.split)]
        end
        orf_results.sort_by { |h| h[:d] }.reverse[0]
      end

      def setup_analysis(seq)
        if opt[:type] == :protein
          data = { seq: [seq], fasta: ">seq\n#{seq}" }
        else
          orfs = seq.scan(/(?=(M\w+))./).flatten
          orfs.unshift(seq)
          data = { seq: orfs, fasta: create_orf_fasta(orfs) }
        end
        data
      end

      def create_orf_fasta(m_orf)
        fasta = ''
        m_orf.each_with_index { |seq, idx| fasta << ">#{idx}\n#{seq}\n" }
        fasta
      end
    end
  end
end
