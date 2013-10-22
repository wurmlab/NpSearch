module NpSearch
  ############# Validating methods ... ##############
  class InputValidators
    # check for the presence of the signal P script.
    def signalp_validator(signalp_dir)
      if File.exist? "#{signalp_dir}/signalp"
        signalp_directory = signalp_dir
      else
        puts # a blank line
        puts "Error: The Signal P directory cannot be found in the following location: \"#{signalp_dir}/\"."
        puts # a blank line
        puts "Please enter the full path or a relative path to the Signal P directory." 
        print "> "
        inp = $stdin.gets.chomp
        until (File.exist? "#{signalp_dir}/signalp") || (File.exist? "#{inp}/signalp")
            puts # a blank line 
            puts "The Signal P directory cannot be found at the following location: \"#{inp}/\""
            puts "Please enter the full path or a relative path to the Signal P directory again..."
            print "> "
            inp = $stdin.gets.chomp
        end       
        signalp_directory = inp
        puts # a blank line
        puts "The Signal P directory has been found at \"#{signalp_directory}/\"..."
        puts # a blank line
      end
      return signalp_directory 
    end

    # checks for the presence of the output directory - if not found, it asks the user whether they want to create the output directory in that directory.
    def output_dir_validator(output_dir)
      unless File.directory? output_dir
        puts # a blank line
        puts "The output directory does not exist."
        puts # a blank line
        puts "The directory \"#{output_dir}\" will be created in this location."
        puts "Do you to continue? [y/n]"
        print "> "
        inp = $stdin.gets.chomp
        until inp.downcase == "n" || inp.downcase == "y"
            puts # a blank line
            puts "The input \"#{inp}\" is not recognised - \"y\" or \"n\" are the only recognisable inputs."
            puts "Please try again."
            puts "The directory \"#{output_dir}\" will be created in this location."
            puts "Do you to continue? [y/n]"
            print "> "
            inp = $stdin.gets.chomp
        end
        if inp.downcase == "y"
            FileUtils.mkdir_p "#{output_dir}" # mkdir_p => make each level of the directory
            puts "Created output directory..."
        elsif inp.downcase == "n"
            abort "\nError: A output directory is required - please create one and then try again.\n\n"
        end            
      end
    end

    # Checks whether the ORF minimum length is a number. Note any digits after the decimal place are ignored.
    def orf_min_length_validator(orf_min_length)
      abort "\nError: The Open Reading Frame (ORF) minimum length must be a whole integer.\n\n" if orf_min_length.to_i < 1 # The .to_i method converts all non-numbers to 0
    end

    # Checks if the file is in fasta format by checking whether the first character on the first line is a ">"
    def probably_fasta(input_file) ### taken from 'database_formatter.rb' from sequenceserver (currently without permission...)
      File.open(input_file, 'r') do |file_stream|
        first_line = file_stream.readline
        if first_line.slice(0,1) == '>'
          return TRUE
        else
          return FALSE
        end
      end
    end

    # Checks whether the input file exists; whether it is empty and whether it is likely a fasta file.
    def input_file_validator(input_file)
      abort "\nError: Input file \"#{input_file}\" does not exist.\n\n" unless File.exist?(input_file)
      abort "\nError: Input file is empty. Please correct this and try again.\n\n" if File.zero?(input_file)
      abort "\nError: The Input file does not seem to be a fasta file. Only fasta files are supported.\n\n" unless probably_fasta(input_file)
    end

    # Checks whether the input_type has been provided in the correct format.
    def input_type_validator(input_type)
      abort "\nError: The Input type \"#{input_type}\" is not recognised - the only two recognised options are \"genetic\" and \"protein\".\n\n" unless input_type.downcase == "genetic" || input_type.downcase == "protein"
    end

    #
    def signalp_version(input_file)
      File.open(input_file, 'r') do |file_stream|
        first_line = file_stream.readline
        if first_line.match(/# SignalP-4.1/)
          return TRUE
        else 
          return FALSE
        end
      end
    end

    #
    def signalp_column_validator(input_file)
      File.open("signalp_out.txt", 'r') do |file_stream|
        secondline = file_stream.readlines[1]
        row = secondline.gsub(/\s+/m, ' ').chomp.split(" ")
        unless row[1] == "name" && row[4] == "Ymax" && row[5] == "pos" && row[9] == "D" 
          return FALSE
        else
          return TRUE 
        end 
      end
    end

    # Ensure that the right version of signal is used.
    def signalp_version_validator(signalp_output_file)
      unless signalp_version(signalp_output_file) # if it is the wrong version 
        #check the columns titles...
        unless signalp_column_validator(signalp_output_file) # i.e. if it has the wrong columns 
          puts # a blank line
          puts "Warning: The wrong version of the signal p has been linked and the signal peptide output is in an unrecognised format."
          puts "Continuing may give you meaningless results."
          puts # a blank line
        else
          puts # a blank line
          puts "Warning: The wrong version of signalp has been linked. However, the signal peptide output file still seems to be in the right format."
          puts # a blank line
        end
        puts "Do you still want to continue? [Y/n]"
        print "> "
        inp = $stdin.gets.chomp
        until inp.downcase == "n" || inp.downcase == "y"
          puts # a blank line
          puts "The input \"#{inp}\" is not recognised - \"y\" or \"n\" are the only recognisable inputs."
          puts "Please try again."
        end
        if inp.downcase == "y"
          puts "Continuing..."
        elsif inp.downcase == "n" 
          abort "\nError: The wrong version of Signal Peptide has been linked. Version 4.1 is the version of signalp currently supported.\n\n"
        end
      end
    end
  end

  
  ############# Converting Input into proper format... ##############
  class Input
    # Reads the input file converting it into hash.
    def read(input_file, type)
      input_read = Hash.new
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


  ############# Translating genetic data into proteome data. ##############
  class Translation 
    # Translate in all 6 frames - with * standing for stop codons
    def translate(input_read)
      protein_data = Hash.new
      input_read.each do |id, sequence|
        for f in (1..6)   # loops, translating in all 6 frames
          protein_data[id + '_f' + f.to_s] = sequence.translate(f)
        end     
      end
      return protein_data
    end

    # Extract all possible Open Reading Frames.
    def extract_orf(protein_data)
      orf = Hash.new
      protein_data.each do |id, sequence|
        identified_orfs = sequence.scan(/(?=(M\w*))./) # Look-Ahead regex scans the sequence for every possible methionine residue to the next stop codon.   
        for i in (0..(identified_orfs.length - 1))
          orf[id + '_' + i.to_s] = identified_orfs[i] # the sequence is put in the array i 
        end
      end
      return orf
    end

    # Extract all those Open Reading Frames that are longer than the minimum length.
    def orf_cleaner(orf, minimum_length)
      orf_condensed = Hash.new
      orf.each do |id, sequence|
        orf_condensed[id] = sequence if (sequence.to_s).length >= (minimum_length + 4) # sequence is in an hash (see method "extract_orf()"), so need to take into account leading [" and trailing "]
      end
      return orf_condensed
    end
  end


  ############# Signal P and Signal P data extraction. ##############
  class Signalp
    @positives = nil
    
    # Runs an external Signal Peptide script from CBS. 
    def signal_p(signalp_dir, input, output)
      system("#{signalp_dir}/signalp -t euk -f short #{input} > #{output}") 
    end

    # Extracts all lines from that Signal P test that show a positives Signal P.
    def signalp_positives_extractor(input)
      @positives = Hash.new
      signalp_file = File.read(input)
      identified_positives = signalp_file.scan(/^.* Y .*$/)
      for i in (0..(identified_positives.length - 1))
        @positives[i] = identified_positives[i]
      end
      return identified_positives.length
    end
     
    # Convert the Signal P positives results (from the Signal P results) into an array and then put all the useful info into a hash
    def array_generator(identified_positives_length)
      signalp_array = Array.new(identified_positives_length){ Array.new(identified_positives_length,0) }
      signalp = Hash.new
      @positives.each do|idx, line|
        row = line.gsub(/\s+/m, ' ').chomp.split(" ") # split the line into a array based on white space.
        raise IO Error, "Badly formatted signal P file - there must be 12 collumns" if row.length != 12
        signalp_array[idx][0..row.length - 1] = row # Merge into existing array
      end
      signalp_array.each do |g|
        seq_id = g[0] 
        cut_off = g[4]
        d_value = g[8]
        signalp[seq_id] = "#{cut_off}//#{d_value}"
      end
      return signalp
    end

    # Uses the info in the signalp hash to present the data as seq ID (with useful info) on one line and the sequence on the next.
    def parse(signalp, open_reading_frames_condensed, motif)
      signalp_with_seq = Hash.new
      signalp.each do |id, cut_off_d_value|
        cut_off_d_value.scan(/(\d+)\/\/(\d+.\d+)/) do |cut_off, d_value| # splits the cut_off_d_value into the cut_off and the d_value... 
          sp_cleavage = cut_off.to_i - 1
          open_reading_frames_condensed.each do |seq_id, seq|
            sequence = seq.to_s.gsub(/\[\"/, "").gsub(/\"\]/, "") # sequence is in an hash (see method "extract_orf()"), so need to take into account leading [" and trailing "].
            sequence.scan(/(.{#{sp_cleavage}})(.*)/) do |signalp, seq_end|
              signalp_with_seq[id + " - S.P. Cleavage Site: #{sp_cleavage}:#{cut_off} - S.P. D-value: #{d_value}"] = "#{signalp}-#{seq_end}" if id == seq_id && seq_end.match(/#{motif}/)
            end
          end
        end
      end
      return signalp_with_seq
    end 
     
    # As usually working with transcriptome data, alternative splicing means that quite usually, you get exactly the same sequence (open reading frame) with different ids. Thus this collapses the seqs into one id.
    def flattener(hash)
      flattened_seq = Hash.new
      hash.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id 
      end
      return flattened_seq.invert # hash is inverted to get HASH[id] = seq which is required for the outputting. 
    end
  end


  ############# Producing the output files ##############
  class Output 
    # converts the hash into a fasta file
    def to_fasta(hash, output)
      output_file = File.new(output, "w")
      hash.each do |id, seq|
        output_file.puts ">" + id
        sequence = seq.to_s.gsub("-", "").gsub("\[\"", "").gsub("\"\]", "")
        output_file.puts sequence
      end
      output_file.close
    end

    # converts the hash into a word document 
    def to_doc(hash, output, motif)
      output_file = File.new(output, "w")
      output_file.puts "<!DOCTYPE html><html><head><style> .id{font-weight: bold;} .signalp{color:#000099; font-weight: bold;} .motif{color:#FF3300; font-weight: bold;} h3 {word-wrap: break-word;} p {word-wrap: break-word; font-family:Courier New, Courier, Mono;}</style></head><body>"
      hash.each do |id, seq|
        sequence = seq.to_s.gsub("\[\"", "").gsub("\"\]", "")
        id.scan(/(\w+)(.*)/) do |id_start, id_end|
          output_file.puts "<p><span class=\"id\"> >#{id_start}</span><span>#{id_end}</span><br>"
          if sequence.match(/-/) # the presence of the "-" means that the signal peptide has been found in the peptide
            output_file.puts "<span class=\"signalp\">"
            sequence.scan(/(\w+)-(\w+)/) do |signalp, seq_end|
              output_file.puts signalp + "</span>" + seq_end.gsub(/#{motif}/, '<span class="motif">\0</span>')
              output_file.puts "</p>"
            end
          else
            output_file.puts sequence + "</p>"
          end
        end
      end
      output_file.puts "</body></html>"
      output_file.close   
    end
  end 
end