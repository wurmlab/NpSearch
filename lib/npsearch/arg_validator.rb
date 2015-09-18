require 'bio'
# Top level module / namespace.
module NpSearch
  # A class that validates the command line opts
  class ArgumentsValidators
    class << self
      def run(opt)
        assert_file_present('input fasta file', opt[:input_file])
        assert_input_file_not_empty(opt[:input_file])
        assert_input_file_probably_fasta(opt[:input_file])
        opt[:type] = assert_input_sequence(opt[:input_file])
        opt[:num_threads] = check_num_threads(opt[:num_threads])
        assert_binaries(opt[:signalp_path], opt[:usearch_path])
        opt
      end

      private

      def assert_file_present(desc, file, exit_code = 1)
        return if file && File.exist?(File.expand_path(file))
        $stderr.puts "*** Error: Couldn't find the #{desc}: #{file}."
        exit exit_code
      end

      def assert_input_file_not_empty(file)
        return unless File.zero?(File.expand_path(file))
        $stderr.puts "*** Error: The input_file (#{file})" \
                     ' seems to be empty.'
        exit 1
      end

      def assert_input_file_probably_fasta(file)
        File.open(file, 'r') do |f|
          fasta = (f.readline[0] == '>') ? true : false
          return fasta if fasta
        end
        $stderr.puts "*** Error: The input_file (#{file})" \
                     ' does not seems to be a fasta file.'
        exit 1
      end

      def assert_input_sequence(file)
        type = type_of_sequences(file)
        return type unless type.nil?
        $stderr.puts '*** Error: The input files seems to contain a mixture of'
        $stderr.puts '    both protein and nucleotide data.'
        $stderr.puts '    Please correct this and try again.'
        exit 1
      end

      def type_of_sequences(file)
        fasta_content = IO.binread(file)
        # the first sequence does not need to have a fasta definition line
        sequences = fasta_content.split(/^>.*$/).delete_if(&:empty?)
        # get all sequence types
        sequence_types = sequences.collect { |seq| guess_sequence_type(seq) }
                         .uniq.compact
        return nil if sequence_types.empty?
        sequence_types.first if sequence_types.length == 1
      end

      def guess_sequence_type(seq)
        # removing non-letter and ambiguous characters
        cleaned_sequence = seq.gsub(/[^A-Z]|[NX]/i, '')
        return nil if cleaned_sequence.length < 10 # conservative
        type = Bio::Sequence.new(cleaned_sequence).guess(0.9)
        (type == Bio::Sequence::NA) ? :nucleotide : :protein
      end

      def check_num_threads(num_threads)
        num_threads = Integer(num_threads)
        unless num_threads > 0
          $stderr.puts 'Number of threads can not be lower than 0'
          $stderr.puts 'Setting number of threads to 1'
          num_threads = 1
        end
        return num_threads unless num_threads > 256
        $stderr.puts "Number of threads set at #{num_threads} is" \
                     ' unusually high.'
      end

      def assert_binaries(signalp_path, usearch_path)
        check_bin('SignalP 4.1 Script', signalp_path) unless signalp_path.nil?
        check_bin('Usearch Script', usearch_path) unless usearch_path.nil?
      end

      def check_bin(desc, bin)
        return if command?("#{bin}")
        $stderr.puts "NpSearch is unable to use the #{desc} at #{bin}"
      end

      # Return `true` if the given command exists and is executable.
      def command?(command)
        system("which #{command} > /dev/null 2>&1")
      end
    end
  end
end
