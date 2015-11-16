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
      create_temp_dir
    end

    def run
      iterate_input_file
      @sorted_sequences = @sequences.sort_by(&:score).reverse
      Output.to_fasta(@opt[:input_file], @sorted_sequences, @opt[:type])
      Output.to_html(@opt[:input_file])
      remove_temp_dir
    end

    private

    def iterate_input_file
      biofastafile = Bio::FlatFile.open(Bio::FastaFormat, @opt[:input_file])
      biofastafile.each_entry do |entry|
        if @opt[:num_threads] > 1
          @pool.schedule(entry) { |e| initialise_seqs(e) }
        else
          initialise_seqs(entry)
        end
      end
      @pool.shutdown if @opt[:num_threads] > 1
    end

    def initialise_seqs(entry)
      if @opt[:type] == :protein
        initialise_protein_seq(entry.entry_id, entry.definition, entry.aaseq)
      else
        initialise_transcriptomic_seq(entry.entry_id, entry.definition,
                                      entry.naseq)
      end
    end

    def initialise_protein_seq(id, sequence)
      return if sequence.length > @opt[:max_seq_length]
      sp = Signalp.analyse_sequence(sequence)
      return if sp[:sp] == 'N'
      seq = Sequence.new(id, sequence, sp)
      puts id
      ScoreSequence.run(seq, @opt)
      @sequences << seq
    end

    def initialise_transcriptomic_seq(id, naseq)
      (1..6).each do |f|
        translated_seq = naseq.translate(f)
        orfs = translated_seq.to_s.scan(/(?=(M\w{#{@opt[:min_orf_length]},}))./)
               .flatten
        initialise_orfs(id, orfs, f)
      end
    end

    def initialise_orfs(id, orfs, frame)
      orfs.each do |orf|
        next if orf.length > @opt[:max_seq_length]
        sp = Signalp.analyse_sequence(orf)
        next if sp[:sp] == 'N'
        puts id
        seq = Sequence.new(id, orf, sp, frame)
        ScoreSequence.run(seq, @opt)
        @sequences << seq
        # The remaining ORF in this frame are simply shorter versions of the
        # same orf so break loop once signal peptide is found.
        break if sp[:sp] == 'Y'
      end
    end

    def create_temp_dir
      return if File.directory?(@opt[:temp_dir])
      FileUtils.mkdir_p(@opt[:temp_dir])
    end

    def remove_temp_dir
      return unless File.directory?(@opt[:temp_dir])
      FileUtils.rm_rf(@opt[:temp_dir])
    end
  end
end
