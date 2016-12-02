require 'forwardable'
require 'open3'
require 'timeout'

# Top level module / namespace.
module NpSearch
  # A class to hold sequence data
  class Signalp
    class << self
      extend Forwardable
      def_delegators NpSearch, :opt, :logger

      def analyse_sequence(seq)
        sp_headers = %w(name cmax cmax_pos ymax ymax_pos smax smax_pos smean d
                        sp dmaxcut networks orf)
        seqs       = setup_analysis(seq)
        sp_results = []
        seqs.each do |sequence|
          sp_results << run_signalp(sequence, sp_headers)
        end
        sp_results.sort_by { |h| h[:d] }.reverse[0]
      end

      private

      def run_signalp(seq, sp_headers)
        Timeout.timeout(300) do
          cmd = "echo '>seq\n#{seq}\n' | #{opt[:signalp_path]} -t euk" \
                ' -f short -U 0.34 -u 0.34'
          stdin, stdout, stderr = Open3.popen3(cmd)
          out = stdout.gets(nil).split("\n").delete_if { |l| l[0] == '#' }
          if out.nil? || out.empty?
            print stdout
            print stderr
            raise ArgumentError, 'Signalp failed to run sucessfully :('
          else
            result = out[0] + ' ' + seq
            return Hash[sp_headers.map(&:to_sym).zip(result.split)]
          end
          stdin.close; stdout.close; stderr.close
        end
      rescue Timeout::Error
        no_results = [0, 0, 1, 1, 1, 1, 1, 1, 1, 'N', 1, 1, seq]
        return Hash[sp_headers.map(&:to_sym).zip(no_results)]
      end

      def setup_analysis(seq)
        orfs = seq.scan(/(?=(M\w{#{opt[:min_orf_length]},}))./).flatten
        opt[:type] == :protein || orfs.empty? || orfs.nil? ? [seq] : orfs
      end
    end
  end
end
