require 'logger'
module NpSearchTranslate
  class Translate
    # Translates in all 6 frames - with * standing for stop codons
    def translate(input_read)
      logger.info { 'Translating the genomic data in all 6 frames.'}
      protein_data = {}
      input_read.each do |id, sequence|
        (1..6).each do |f|
          protein_data[id + '_f' + f.to_s] = sequence.translate(f)
        end
      end
      return protein_data
    end

    # Extract all possible Open Reading Frames.
    def extract_orf(protein_data)
      orf = {}
      protein_data.each do |id, sequence|
        identified_orfs = sequence.scan(/(?=(M\w*))./)
        (0..(identified_orfs.length - 1)).each do |i|
          orf[id + '_' + i.to_s] = identified_orfs[i]
        end
      end
      return orf
    end

    # Extracts all Open Reading Frames that are longer than the minimum length.
    def orf_cleaner(orf, minimum_length)
      orf_clean = {}
      orf.each do |id, sequence|
        if (sequence.to_s).length >= (minimum_length + 4)
          orf_clean[id] = sequence 
        end
      end
      return orf_clean
    end
  end
end