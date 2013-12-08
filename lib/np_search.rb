require 'logger'

LOG = Logger.new(STDOUT)
LOG.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
end
LOG.level = Logger::FATAL # set level to only show fatal

module NpSearch
  class Validators
    # Overides the  LOG levels if required.
    def initialize(verbose_opt, debug_opt)
      LOG.level = Logger::INFO if verbose_opt == 'verbose'
      LOG.level = Logger::DEBUG if debug_opt == 'debug'
    end

    # Checks for the presence of the Signal Peptide Script.
    def signalp_validator(signalp_dir)
      if File.exist? "#{signalp_dir}/signalp"
        signalp_directory = signalp_dir
      else
        puts # a blank line
        puts "Error: The Signal Peptide Script directory cannot be found" \
             " in the following location: '{signalp_dir}/'."
        puts # a blank line
        puts 'Please enter the full path or a relative path to the Signal' \
             ' Peptide Script directory (i.e. to the folder containing the' \
             ' SignalP script).'
        print '> '
        inp = $stdin.gets.chomp
        until (File.exist? "#{signalp_dir}/signalp") || \
              (File.exist? "#{inp}/signalp")
          puts # a blank line
          puts "The Signal P directory cannot be found at the following" \
               " location: '#{inp}'"
          puts 'Please enter the full path or a relative path to the Signal'\
               ' Peptide directory again.'
          print '> '
          inp = $stdin.gets.chomp
        end
        signalp_directory = inp
        puts # a blank line
        puts "The Signal P directory has been found at '#{signalp_directory}'"
        puts # a blank line
      end
      return signalp_directory
    end

    # Checks for the presence of the output directory; if not found, it asks
    #   the user whether they want to create the output directory.
    def output_dir_validator(output_dir)
      unless File.directory? output_dir
        puts # a blank line
        puts 'The output directory does not exist.'
        puts # a blank line
        puts "The directory '#{output_dir}' will be created in this location."
        puts 'Do you to continue? [y/n]'
        print '> '
        inp = $stdin.gets.chomp
        until inp.downcase == 'n' || inp.downcase == 'y'
          puts # a blank line
          puts "The input: '#{inp}' is not recognised - 'y' or 'n' are the" \
               " only recognisable inputs."
          puts 'Please try again.'
          puts "The directory '#{output_dir}' will be created in this" \
               " location."
          puts 'Do you to continue? [y/n]'
          print '> '
          inp = $stdin.gets.chomp
        end
        if inp.downcase == 'y'
          FileUtils.mkdir_p "#{output_dir}"
          puts 'Created output directory...'
        elsif inp.downcase == 'n'
          abort "\nError: A output directory is required - please create" \
                "one and then try again.\n\n"
        end
      end
    end

    # Ensures that the ORF minimum length is a number. Any digits after the
    #   decimal place are ignored.
    def orf_min_length_validator(orf_min_length)
      abort "\nError: The Open Reading Frame (ORF) minimum length must be a" \
            " whole integer.\n\n" if orf_min_length.to_i < 1
    end

    # Taken from 'database_formatter.rb' from sequenceserver.
    def probably_fasta(input_file)
      File.open(input_file, 'r') do |file_stream|
        first_line = file_stream.readline
        if first_line.slice(0, 1) == '>'
          return TRUE
        else
          return FALSE
        end
      end
    end

    # Checks whether the input file exists; whether it is empty and whether it
    #   is likely a fasta file.
    def input_file_validator(input_file)
      abort "\nError: The input file '#{input_file}' does not exist.\n\n" \
            unless File.exist?(input_file)
      abort "\nError: The input file is empty. Please correct this and" \
            " try again.\n\n" if File.zero?(input_file)
      abort "\nError: The input file does not seem to be a fasta file. Only" \
            " fasta files are supported.\n\n" unless probably_fasta(input_file)
    end

    # Checks whether the input_type has been provided in the correct format.
    def input_type_validator(input_type)
      abort "\nError: The input type: '#{input_type}' is not recognised;" \
            " the only recognised options are 'genetic' and 'protein'.\n\n" \
            unless input_type.downcase == 'genetic' || \
            input_type.downcase == 'protein'
    end

    # Checks whether the right version of Signal Peptide Script has been
    #   linked to the program.
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

    # Checks whether the Signal P script output is in the right format by
    #   checking whether the necessary columns are exactly the same.
    def signalp_column_validator(input_file)
      File.open('signalp_out.txt', 'r') do |file_stream|
        secondline = file_stream.readlines[1]
        row = secondline.gsub(/\s+/m, ' ').chomp.split(' ')
        if row[1] != 'name' && row[4] != 'Ymax' && row[5] != 'pos' && \
           row[9] != 'D'
          return TRUE
        else
          return FALSE
        end
      end
    end

    # Ensure that the right version of signal is used.
    def signalp_version_validator(signalp_output_file)
      unless signalp_version(signalp_output_file)
      # i.e. if Signal P is the wrong version
        if signalp_column_validator(signalp_output_file)
          puts # a blank line
          puts 'Warning: The wrong version of signalp has been linked.' \
               ' However, the signal peptide output file still seems to' \
               ' be in the right format.'
          puts # a blank line
        else
          puts # a blank line
          puts 'Warning: The wrong version of the signal p has been linked' \
               ' and the signal peptide output is in an unrecognised format.'
          puts 'Continuing may give you meaningless results.'
          puts # a blank line
        end
        puts 'Do you still want to continue? [y/n]'
        print '> '
        inp = $stdin.gets.chomp
        until inp.downcase == 'n' || inp.downcase == 'y'
          puts # a blank line
          puts "The input: '#{inp}' is not recognised - 'y' or 'n' are the" \
               " only recognisable inputs."
          puts 'Please try again.'
        end
        if inp.downcase == 'y'
          puts 'Continuing.'
        elsif inp.downcase == 'n'
          abort "\nError: The wrong version of Signal Peptide has been " \
                "linked. Version 4.1 is the version of signalp currently" \
                "supported.\n\n"
        end
      end
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
    # Translates in all 6 frames - with * standing for stop codons
    def translate(input_read)
      LOG.info { 'Translating the genomic data in all 6 frames.' }
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
      LOG.info { 'Extracting all Open Reading Frames from all 6 possible frames. This is every methionine residue to the next stop codon.' }
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
      LOG.info { "Removing all Open Reading Frames that are shorter than #{ORF_min_length}." }
      orf_clean = {}
      orf.each do |id, sequence|
        if (sequence.to_s).length >= (minimum_length + 4)
          orf_clean[id] = sequence
        end
      end
      return orf_clean
    end
  end

  class Signalp
    # Runs an external Signal Peptide script from CBS.
    def signalp(signalp_dir, input, output)
      LOG.info { 'Running a Signal Peptide test on each sequence.' }
      system("#{signalp_dir}/signalp -t euk -f short #{input} > #{output}")
      LOG.info { "Writing the Signal Peptide test results to the file '#{output}'." }
    end
  end

  class Analysis
    attr_accessor :positives

    def initialize
      @positives = nil
    end

    # Creates a signalp positives file, if required.
    def signalp_positives_file_writer(input, identified_positives, output)
      LOG.info { "Writing the Signal Peptide test results to the file '#{output}'." }
      output_file = File.new(output, 'w')
      File.open(input, 'r') do |file_stream|
        first_line = file_stream.readline
        secondline = file_stream.readlines[0]
        output_file.puts first_line
        output_file.puts secondline
      end
      output_file.puts identified_positives
      output_file.close
    end

    # Extracts rows from the Signal P test that are positive.
    def signalp_positives_extractor(input, output_file, make_file)
      LOG.info { 'Extracting all Open Reading Frames that have a Signal Peptide.' }
      @positives = {}
      signalp_file = File.read(input)
      identified_positives = signalp_file.scan(/^.* Y .*$/)
      if make_file == 'signalp_positives_file'
        signalp_positives_file_writer(input, identified_positives, output_file)
      end
      (0..(identified_positives.length - 1)).each do |i|
        @positives[i] = identified_positives[i]
      end
      return identified_positives.length
    end

    # Converts the Signal P positives results into an array and then put all
    #   the useful info into a hash
    def array_generator(identified_positives_length)
      signalp_array = Array.new(identified_positives_length)\
                      { Array.new(identified_positives_length, 0) }
      signalp_hash = {}
      @positives.each do|idx, line|
        row = line.gsub(/\s+/m, ' ').chomp.split(' ')
        signalp_array[idx][0..row.length - 1] = row # Merge into existing array
      end
      signalp_array.each do |h|
        seq_id = h[0]
        cut_off = h[4]
        d_value = h[8]
        signalp_hash[seq_id] = [cut_off: cut_off, d_value: d_value]
      end
      return signalp_hash
    end

    # Presents the signal P positives data with seq Id on onto line and the
    #   sequence on the next.
    def parse(signalp_hash, orf_clean, motif)
      LOG.info { 'Extracting sequences that have at least 1 neuropeptide cleavage site after the signal peptide cleavage site.' }
      signalp_with_seq = {}
      signalp_hash.each do |id, h|
        current_orf = orf_clean[id].to_s.gsub('["', '').gsub('"]', '')
        cut_off     = h[0][:cut_off]
        d_value     = h[0][:d_value]
        sp_clv      = cut_off.to_i - 1
        signalp     = current_orf[0, sp_clv]
        seq_end     = current_orf[sp_clv, current_orf.length]
        if seq_end.match(/#{motif}/)
          signalp_with_seq[id + "~- S.P.=> Cleavage Site: #{sp_clv}:#{cut_off} | D-value: #{d_value}"] = "#{signalp}~#{seq_end}"
        end 
      end
      return signalp_with_seq
    end

    # With transcriptome data, alternative splicing means duplicates ORF, so
    #   this method collapses duplicates into one reading.
    def flattener(signalp_with_seq)
      LOG.info { 'Removing all duplicate entries.' }
      flattened_seq = {}
      signalp_with_seq.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id
      end
      return flattened_seq.invert # Format required for the outputting.
    end
  end

  class Output
    def to_fasta(what, hash, output)
      LOG.info { "Writing the #{what} to the file:'#{output}'." }
      output_file = File.new(output, 'w')
      hash.each do |id, seq|
        output_file.puts '>' + id.gsub('~', '')
        sequence = seq.to_s.gsub('~', '').gsub('["', '').gsub('"]', '')
        output_file.puts sequence
      end
      output_file.close
    end

    def make_doc_hash(hash, motif)
      doc_hash = {}
      hash.each do |id, seq|
        id, id_end = id.split('~').map(&:strip)
        signalp, seq_end = seq.split('~').map(&:strip)
        seq = seq_end.gsub(/#{motif}/, '<span class="motif">\0</span>')\
        .gsub('G<span class="motif">', \
              '<span class="glycine">G</span><span class="motif">')
        doc_hash[id] = [id_end: id_end, signalp: signalp, seq: seq]
      end
      return doc_hash
    end

    def to_doc(doc_hash, output)
haml_doc = <<EOT
!!!
%html
  %head
    :css
      .id {font-weight: bold;}
      .signalp {color:#000099; font-weight: bold;}
      .motif {color:#FF3300; font-weight: bold;}
      .glycine {color:#00FF00; font-weight: bold;}
      p {word-wrap: break-word; font-family:Courier New, Courier, Mono;}
  %body
    - doc_hash.each do |id, hash|
      %p
        %span.id= id
        %span= hash[0][:id_end]
        %br/
        %span.signalp= hash[0][:signalp] + "</span><span>" + hash[0][:seq]
EOT
      engine = Haml::Engine.new(haml_doc)
      output_file = File.new(output, 'w')
      output_file.puts engine.render(Object.new, doc_hash: doc_hash)
      LOG.info { "Writing the final output file to the file:'#{output}'." }
      output_file.close
    end
  end
end