require 'forwardable'

# Top level module / namespace.
module NpSearch
  # A class to hold sequence data
  class Signalp
    class << self
      extend Forwardable
      def_delegators NpSearch, :opt

      def analyse_sequence(seq)
        sp_headers = %w(name cmax cmax_pos ymax ymax_pos smax smax_pos smean d
                        sp dmaxcut networks)
        s = `echo ">seq\n#{seq}\n" | #{opt[:signalp_path]} -t euk -f short \
             -U 0.3 -u 0.3`
        Hash[sp_headers.map(&:to_sym).zip(s.gsub(/^#.*\n/, '').split)]
      end
    end
  end
end
