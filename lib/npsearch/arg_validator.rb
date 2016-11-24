require 'bio'
require 'forwardable'

# Top level module / namespace.
module NpSearch
  # A class that validates the command line opts
  class ArgumentsValidators
    class << self
      extend Forwardable
      def_delegators NpSearch, :logger

      def run(opt)
        assert_file_present('input fasta file', opt[:input_file])
        opt[:input_file] = File.expand_path(opt[:input_file])
        assert_input_file_not_empty(opt[:input_file])
        assert_input_file_probably_fasta(opt[:input_file])
        opt[:type]        = assert_input_sequence(opt[:input_file])
        opt[:num_threads] = check_num_threads(opt[:num_threads])
        assert_binaries('SignalP 4.1 Script', opt[:signalp_path])
        logger.debug "The validated OPT hash contains: #{opt}"
        opt
      end

      private

      def assert_file_present(desc, file, exit_code = 1)
        logger.debug "Testing if the #{desc} exists: '#{file}'."
        return if file && File.exist?(File.expand_path(file))
        error_msg = "*** Error: Couldn't find the #{desc}: '#{file}'."
        logger.fatal error_msg
        $stderr.puts error_msg
        exit exit_code
      end

      def assert_input_file_not_empty(file)
        logger.debug "Testing if the input file ('#{file}') is empty."
        return unless File.zero?(File.expand_path(file))
        error_msg = "*** Error: The input_file ('#{file}') seems to be empty."
        logger.fatal error_msg
        $stderr.puts error_msg
        exit 1
      end

      def assert_input_file_probably_fasta(file)
        logger.debug("Testing whether the input, ('#{file}') is a fasta file.")
        File.open(file, 'r') do |f|
          fasta = f.readline[0] == '>' ? true : false
          return fasta if fasta
        end
        error_msg = "*** Error: The input file (#{file}) does not seems to be" \
                     ' to be a fasta file.'
        logger.fatal error_msg
        $stderr.puts error_msg
        exit 1
      end

      def assert_input_sequence(file)
        type = type_of_sequences(file)
        return type unless type.nil?
        error_msg = '*** Error: The input files seems to contain a mixture of' \
                    ' both protein and nucleotide data.' \
                    ' Please correct this and try again.'
        logger.fatal error_msg
        $stderr.puts error_msg
        exit 1
      end

      # determine file sequence type based on first 500 lines
      def type_of_sequences(file)
        logger.debug 'Checking the type of sequence in the input file based' \
                     ' on the first 500 lines.'
        fasta_content = File.foreach(file).first(500).join("\n")
        # the first sequence does not need to have a fasta definition line
        sequences = fasta_content.split(/^>.*$/).delete_if(&:empty?)
        # get all sequence types
        sequence_types = sequences.collect { |seq| guess_sequence_type(seq) }
                                  .uniq.compact
        logger.debug " The guessed typed of Sequences are: #{sequence_types}"
        return nil if sequence_types.empty?
        sequence_types.first if sequence_types.length == 1
      end

      def guess_sequence_type(seq)
        cleaned_sequence = seq.gsub(/[^A-Z]|[NX]/i, '')
        return nil if cleaned_sequence.length < 10 # conservative
        type = Bio::Sequence.new(cleaned_sequence).guess(0.9)
        type == Bio::Sequence::NA ? :genetic : :protein
      end

      def check_num_threads(num_threads)
        logger.debug "Checking the number of threads: #{num_threads}"
        num_threads = Integer(num_threads)
        unless num_threads > 0
          warn_msg = 'Number of threads can not be lower than 0. Changing' \
                     ' number of threads to 1'
          logger.warn warn_msg
          $stderr.puts warn_msg
          num_threads = 1
        end
        return num_threads unless num_threads > 256
        warn_msg = "Number of threads set at #{num_threads} is unusually high."
        logger.warn warn_msg
        $stderr.puts warn_msg
      end

      def assert_binaries(desc, bin)
        logger.debug "Checking #{desc} binary at: #{bin}."
        return if command?(bin.to_s)
        warn_msg = "NpSearch is unable to use the #{desc} at #{bin}"
        logger.warn warn_msg
        $stderr.puts warn_msg
      end

      # Return `true` if the given command exists and is executable.
      def command?(command)
        system("which #{command} > /dev/null 2>&1")
      end
    end
  end
end
