require 'logger'
module NpSearch
  class Validators
    def all_validators(signalp_dir, output_dir, min_length, input, input_type)
      input_validators = NpSearchValidators::Validators.new 
      signalp_directory = input_validators.signalp_validator(signalp_dir) 
      input_validators.output_dir_validator(output_dir) 
      input_validators.orf_min_length_validator(min_length) 
      input_validators.input_file_validator(input) 
      input_validators.input_type_validator(input_type)
      return signalp_directory
    end
  end

  class Input
    # Reads the input file converting it into hash.
    def read(input_file, type)
      input_read = {}
      biofastafile = Bio::FlatFile.open(Bio::FastaFormat, input_file)
      biofastafile.each_entry do |entry|
        case type.downcase
        when 'genetic'
          seq = entry.naseq
        when 'protein'
          seq = entry.aaseq
        end
        input_read[entry.entry_id] = seq
      end
      return input_read
    end
  end

  class Translation
    def
    # Translation
    translation_new = NpSearchTranslate::Translate.new
    translated_sequences = translation_new.translate(input_read)
    output_new.to_fasta(translated_sequences, "#{output_dir}/protein.fa") if options[:output_all] 
    # Open Reading Frame Extraction.
    logger.info { 'Extracting all Open Reading Frames from all 6 possible frames. This is every methionine residue to the next stop codon.' }
    orf = translation_new.extract_orf(translated_sequences)
    logger.info { "Writing the extracted Open Reading Frames to the file '#{output_dir}/orf.fa'." } if options[:output_all] 
    output_new.to_fasta(orf, "#{output_dir}/orf.fa") if options[:output_all] 
    logger.info { "Removing all Open Reading Frames that are shorter than #{ORF_min_length}." }
    orf_clean = translation_new.orf_cleaner(orf, ORF_min_length)
    logger.info { "Writing the cleaned Open Reading Frames to the file '#{output_dir}/orf_clean.fa'." }
    output_new.to_fasta(orf_clean, "#{output_dir}/orf_clean.fa") 
  end

  
end
