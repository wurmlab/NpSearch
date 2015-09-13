require 'forwardable'
require 'tempfile'

module NpSearch
  # A class to hold sequence data
  class Signalp
    class << self
      extend Forwardable
      def_delegators NpSearch, :opt

      def analyse_sequence(seq)
        sp_headers = %w(name cmax cmax_pos ymax ymax_pos smax smax_pos smean d
                        sp dmaxcut networks)
        f = Tempfile.new('signalp')
        f.write(">seq\n#{seq}")
        f.close
        s = `#{opt[:signalp_path]} -t euk -f short -U 0.3 -u 0.3 '#{f.path}' | \
             sed -n '3 p'`
        Hash[sp_headers.map(&:to_sym).zip(s.split)]
      ensure
        f.unlink
      end
    end
  end
end
