module NpSearch
  # A class that validates the command line opts
  class ArgumentsValidators
    class << self
      def run(opt)
        @opt = opt
        assert_file_present('input fasta file', @opt[:input_file])
        assert_input_file_not_empty
        assert_input_file_probably_fasta
        @opt[:type] = guess_sequence_type
        assert_input_sequence
        check_num_threads
        assert_binaries
        @opt
      end

      private

      def assert_file_present(desc, file, exit_code = 1)
        return if file && File.exist?(File.expand_path(file))
        $stderr.puts "*** Error: Couldn't find the #{desc}: #{file}."
        exit exit_code
      end

      def assert_input_file_not_empty
        return unless File.zero?(File.expand_path(@opt[:input_file]))
        $stderr.puts "*** Error: The input_file (#{@opt[:input_file]})" \
                     ' seems to be empty.'
        exit 1
      end

      def assert_input_file_probably_fasta
        File.open(@opt[:input_file], 'r') do |f|
          fasta = (f.readline[0] == '>') ? true : false
          return fasta if fasta
        end
        $stderr.puts "*** Error: The input_file (#{@opt[:input_file]})" \
                     ' does not seems to be a fasta file.'
        exit 1
      end

      def guess_sequence_type
        fasta_content = IO.binread(@opt[:input_file])
        # removing non-letter and ambiguous characters
        cleaned_sequence = fasta_content.gsub(/[^A-Z]|[NX]/i, '')
        return nil if cleaned_sequence.length < 10 # conservative
        type = Bio::Sequence.new(cleaned_sequence).guess(0.9)
        (type == Bio::Sequence::NA) ? :nucleotide : :protein
      end

      def assert_input_sequence
        return if @opt[:type] == :nucleotide || @opt[:type] == :protein
        $stderr.puts '*** Error: The input files does not contain just protein'
        $stderr.puts '    or nucleotide data, but seems to be a mixture of'
        $stderr.puts '    both protein and nucleotide data.'
        $stderr.puts '    Please correct this and try again.'
        exit 1
      end

      def check_num_threads
        @opt[:num_threads] = Integer(@opt[:num_threads])
        unless @opt[:num_threads] > 0
          $stderr.puts 'Number of threads can not be lower than 0'
          $stderr.puts 'Setting number of threads to 1'
          @opt[:num_threads] = 1
        end
        return unless @opt[:num_threads] > 256
        $stderr.puts "Number of threads set at #{@opt[:num_threads]} is" \
                     ' unusually high.'
      end

      def assert_binaries
        check_bin('SignalP 4.1 Script', @opt[:signalp_path], '-V')
        check_bin('Usearch Script', @opt[:usearch_path], '--version')
      end

      def check_bin(desc, bin, sub_command)
        assert_file_present(desc, bin)
        return if command?("#{bin} #{sub_command}")
        $stderr.puts "NpSearch is unable to use the #{desc} at #{bin}"
      end

      # Return `true` if the given command exists and is executable.
      def command?(command)
        system("which #{command} > /dev/null 2>&1")
      end
    end
  end
end
