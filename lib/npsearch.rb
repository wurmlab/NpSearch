require 'bio'
require 'fileutils'

require 'npsearch/arg_validator'
require 'npsearch/output'
require 'npsearch/pool'
require 'npsearch/scoresequence'
require 'npsearch/sequence'
require 'npsearch/signalp'

# Top level module / namespace.
module NpSearch
  class <<self
    attr_accessor :opt
    attr_accessor :sequences
    attr_reader :sorted_sequences

    def init(opt)
      @opt              = ArgumentsValidators.run(opt)
      @sequences        = []
      @sorted_sequences = nil
      @pool             = Pool.new(@opt[:num_threads]) if @opt[:num_threads] > 1
      FileUtils.mkdir_p(@opt[:temp_dir])
      extract_orf if @opt[:type] == :genetic
    end

    def run
      input_file = @opt[:type] == :protein ? @opt[:input_file] : @opt[:orf]
      iterate_input_file(input_file)
      @sorted_sequences = @sequences.sort_by(&:score).reverse
      Output.to_fasta(@opt[:input_file], @sorted_sequences, @opt[:type])
      Output.to_html(@opt[:input_file])
      remove_temp_dir
    end

    private

    # Uses getorf from EMBOSS package to extract all ORF
    def extract_orf(input = @opt[:input_file], minsize = 90)
      @opt[:orf] = File.join(@opt[:temp_dir], 'input.orf.fa')
      system "getorf -sequence #{input} -outseq #{@opt[:orf]}" \
             " -minsize #{minsize} >/dev/null 2>&1"
    end

    def iterate_input_file(input_file)
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
      return if entry.aaseq.length > @opt[:max_orf_length]
      sp = Signalp.analyse_sequence(entry.aaseq.to_s)
      return if sp[:sp] == 'N'
      # seq = Sequence.new(entry.entry_id, entry.definition, entry.aaseq, sp)
      seq = Sequence.new(entry, sp)
      ScoreSequence.run(seq, @opt)
      @sequences << seq
    end

    def remove_temp_dir
      return unless File.directory?(@opt[:temp_dir])
      FileUtils.rm_rf(@opt[:temp_dir])
    end
  end
end
