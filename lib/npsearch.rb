require 'bio'
require 'english'
require 'fileutils'

require 'npsearch/arg_validator'
require 'npsearch/logger'
require 'npsearch/output'
require 'npsearch/pool'
require 'npsearch/scoresequence'
require 'npsearch/sequence'
require 'npsearch/signalp'

# Top level module / namespace.
module NpSearch
  class <<self
    attr_accessor :logger
    attr_accessor :opt
    attr_accessor :sequences
    attr_reader :sorted_sequences

    def init(opt)
      @opt = opt
      ArgumentsValidators.run(opt)
      @sequences        = []
      @sorted_sequences = nil
      @pool             = initialise_thread_pool
      create_temp_directory
      extract_orf
    end

    def run
      input_file = @opt[:type] == :genetic ? @opt[:orf] : @opt[:input_file]
      iterate_input_file(input_file)
      @sorted_sequences = @sequences.sort_by(&:score).reverse
      Output.to_fasta(@opt[:input_file], @sorted_sequences, @opt[:type])
      Output.to_html(@opt[:input_file])
      remove_temp_dir
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT, @opt[:debug])
    end

    def initialise_thread_pool
      return if @opt[:num_threads] == 1
      logger.debug "Creating a thread pool of size #{@opt[:num_threads]}"
      Pool.new(@opt[:num_threads])
    end

    def create_temp_directory
      FileUtils.mkdir_p(@opt[:temp_dir])
      logger.debug "Successfully creating temp directory at: #{@opt[:temp_dir]}"
    end

    # Uses getorf from EMBOSS package to extract all ORF
    def extract_orf(input = @opt[:input_file], minsize = 90)
      return if @opt[:type] == :protein
      logger.debug 'Attempting to extract ORF.'
      @opt[:orf] = File.join(@opt[:temp_dir], 'input.orf.fa')
      cmd = "getorf -sequence #{input} -outseq #{@opt[:orf]}" \
            " -minsize #{minsize} >/dev/null 2>&1"
      logger.debug "Running: #{cmd}"
      system(cmd)
      logger.debug("EGexit Code: #{$CHILD_STATUS.exitstatus}")
    end

    def iterate_input_file(input_file)
      logger.debug "Iterating the Input File: #{input_file}"
      Bio::FlatFile.open(Bio::FastaFormat, input_file).each_entry do |entry|
        if @opt[:num_threads] > 1
          @pool.schedule(entry) { |e| initialise_seqs(e) }
        else
          initialise_seqs(entry)
        end
      end
      @pool.shutdown if @opt[:num_threads] > 1
    end

    def initialise_seqs(entry)
      logger.debug "-- Analysing: '#{entry.definition}' (#{entry.aaseq.length})"
      return if entry.aaseq.length > @opt[:max_orf_length]
      sp = Signalp.analyse_sequence(entry.aaseq.to_s)
      return if sp[:sp] == 'N'
      seq = Sequence.new(entry, sp)
      ScoreSequence.run(seq, @opt)
      @sequences << seq
    end

    def remove_temp_dir
      return unless File.directory?(@opt[:temp_dir])
      logger.debug "Deleting Temporary directory: #{@opt[:temp_dir]}"
      FileUtils.rm_rf(@opt[:temp_dir])
    end
  end
end
