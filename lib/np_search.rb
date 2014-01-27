require 'logger'

LOG = Logger.new(STDOUT)
LOG.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
end
LOG.level = Logger::FATAL # set to only show fatal messages

module NpSearch
  class Validators
    # Overides the  LOG levels if required.
    def initialize(verbose_opt, help_banner)
      LOG.level = Logger::INFO if verbose_opt.to_s == 'true'
      @help_banner = help_banner
    end

    def arg_vldr(motif, input_type, input, output_dir)
      if motif == nil
        puts # a blank line
        puts 'Usage Error: No Query Motif ("-m" option) is supplied.'
      end

      if input_type == nil
        puts # a blank line
        puts 'Usage Error: No Input Type ("-t" option) is supplied.'
      end

      if input == nil
        puts # a blank line
        puts 'Usage Error: No Input file ("-i option") is supplied.'
      end

      if output_dir == nil
        puts # a blank line
        puts 'Usage Error: No Output Folder ("-o" option) is supplied.'
      end

      if input == nil || input_type == nil || motif == nil || output_dir == nil
        puts @help_banner
        exit
      end
    end

    # Ensures that the ORF minimum length is a number. Any digits after the
    #   decimal place are ignored.
    def orf_min_length_vldr(orf_min_length)
      if orf_min_length.to_i < 1
        puts # a blank line
        puts 'Usage Error: The Open Reading Frames minimum length can only be' \
             ' a full integer.'
        puts @help_banner
        exit 
      end  
    end

    def extract_orf_conflict(input_type, extract_orf)
      if input_type == 'protein' && extract_orf == TRUE
        puts # a blank line
        puts 'Usage Error: Conflicting arguments detected: the Extract_ORF' \
             ' option (option "-e") is only available when input file contains'\
             ' genetic data.'
        puts @help_banner
        exit
      end
    end

    def input_sp_file_conflict(input_type, signalp_file)
      if input_type == 'genetic' && signalp_file != nil
        puts # a blank line
        puts 'Usage Error: Conflicting arguments detected: the signalp input' \
             ' option (option "-s") is only available when input file contains'\
             ' protein data.'
        puts @help_banner
        exit
      end
    end

    # Checks whether the input_type has been provided in the correct format.
    def input_type_vldr(input_type)
      unless input_type.downcase == 'genetic' || \
             input_type.downcase == 'protein'
        puts # a blank line
        puts "Usage Error: The input_type: '#{input_type} is not recognised" \
             " The input_type option ('-t' option) can either be 'genetic'" \
             " or 'protein.'"
        puts @help_banner
        exit
      end
    end

    ### Input file Validators...
    # Adapted from 'database_formatter.rb' from sequenceserver.
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
    def input_file_vldr(input_file)
      unless File.exist?(input_file)
        puts # a blank line
        puts "Critical Error: The input file '#{input_file}' does not exist"
        puts @help_banner
        exit
      end
      if File.zero?(input_file)
        puts # a blank line
        puts "Critical Error: The input file '#{input_file}' is empty."
        puts @help_banner
        exit
      end
      unless probably_fasta(input_file)
        puts # a blank line
        puts "Critical Error: The input file '#{input_file}' does not seem to" \
             " in fasta format - the input file must be in fasta format."
        puts @help_banner
        exit
      end
    end


    ### Output folder Validator...
    # Checks for the presence of the output directory; if not found, it asks
    #   the user whether they want to create the output directory.
    def output_dir_vldr(output_dir)
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
          puts # a blank line
          puts 'Critical Error: An output directory is required; please' \
               ' create an output directory and then try again.'
          puts @help_banner
          exit
        end
      end
    end

    ### SignalP Validators...
    # Checks for the presence of the Signal Peptide Script.
    def sp_vldr(signalp_dir)
      if File.exist? "#{signalp_dir}/signalp"
        signalp_directory = signalp_dir
      else
        puts # a blank line
        puts "Error: The Signal Peptide Script directory cannot be found" \
             " in the following location: '#{signalp_dir}/'."
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
          puts 'Please enter the full path or a relative path to the Signal' \
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

    # Checks whether the right version of Signal Peptide Script has been
    #   linked to the program.
    def sp_version(input_file)
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
    def sp_column_vldr(input_file)
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
    def sp_version_vldr(signalp_output_file)
      unless sp_version(signalp_output_file)
      # i.e. if Signal P is the wrong version
        if sp_column_vldr(signalp_output_file)
          puts # a blank line
          puts 'Warning: The wrong version of signalp has been linked.' \
               ' However, the signal peptide output file still seems to' \
               ' be in the right format.'
        else
          puts # a blank line
          puts 'Warning: The wrong version of the signal p has been linked' \
               ' and the signal peptide output is in an unrecognised format.'
          puts 'Continuing may give you meaningless results.'
        end
        puts # a blank line
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
          puts # a blank line
          puts 'Critical Error: Currently NpSearch only supports the 4.1' \
               ' version of the signal p script. Please ensure the correct' \
               ' version of the signal p script is downloaded.'
          exit
        end
      end
    end

    def @hash.empty(hash, output_message)
      if hash.empty?
        puts # a blank line
        puts 'A Critical Error occured in '
        print output_message
        puts # a blank line 
        puts 'Please ensure all the input arguments are correct and then try' \
             ' again.'
        puts @help_banner
        exit
      end
    end

    #Set global variable so that other methods can access method.
    @hash = Validators.new('other', @help_banner)
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
      @hash.empty(input_read, 
                  'converting the input data into the required format.')
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
      @hash.empty(protein_data, 'translating the input data in all 6 frames.')
      return protein_data
    end

    # Extract all possible Open Reading Frames.
    def extract_orf(protein_data)
      LOG.info { 'Extracting all Open Reading Frames from all 6 possible' \
                 ' frames. This is every methionine residue to the next stop' \
                 ' codon.' }
      orf = {}
      protein_data.each do |id, sequence|
        identified_orfs = sequence.scan(/(?=(M\w*))./)
        (0..(identified_orfs.length - 1)).each do |i|
          orf[id + '_' + i.to_s] = identified_orfs[i]
        end
      end
      @hash.empty(orf, 
                  'extracting Open Reading Frames (ORF). This could be due to' \
                  ' the fact that there are no ORF in the data.')
      return orf
    end

    # Extracts all Open Reading Frames that are longer than the minimum length.
    def orf_cleaner(orf, minimum_length)
      LOG.info { "Removing all Open Reading Frames that are shorter than "\
                 "#{minimum_length}." }
      orf_clean = {}
      orf.each do |id, sequence|
        if (sequence.to_s).length >= (minimum_length + 4)
          orf_clean[id] = sequence
        end
      end
      @hash.empty(orf, 
                  'removing Open Reading Frames that are smaller than the' \
                        '  critical length (ORF_min_length).')
      return orf_clean
    end
  end

  class Signalp
    # Runs an external Signal Peptide script from CBS.
    def signalp(signalp_dir, input, output)
      LOG.info { 'Running a Signal Peptide test on each sequence.' }
      system("#{signalp_dir}/signalp -t euk -f short #{input} > #{output}")
      LOG.info { "Writing the Signal Peptide test results to the file " \
                 "'#{output}'." }
    end
  end

  class Analysis
    attr_accessor :positives

    def initialize
      @positives = nil
    end

    # Creates a signalp positives file, if required.
    def sp_positives_file_writer(input, identified_positives, output)
      LOG.info { "Writing the Signal Peptide test results to the file " \
                 "'#{output}'." }
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
    def sp_positives_extractor(input, output_file, make_file)
      LOG.info { 'Extracting all sequences that have a Signal Peptide.' }
      @positives = {}
      signalp_file = File.read(input)
      identified_positives = signalp_file.scan(/^.* Y .*$/)
      if make_file == 'sp_positives_file'
        sp_positives_file_writer(input, identified_positives, output_file)
      end
      (0..(identified_positives.length - 1)).each do |i|
        @positives[i] = identified_positives[i]
      end
      @hash.empty(@positives, 
                  'extracting sequences with a secretory signal peptide.' \
                  ' This is could be due to the fact that there are no' \
                  ' sequences with a signal peptide.')
      return identified_positives.length
    end

    # Converts the Signal P positives results into an array and then put all
    #   the useful info into a hash
    def array_generator(identified_positives_length)
      sp_array = Array.new(identified_positives_length)\
                      { Array.new(identified_positives_length, 0) }
      sp_hash = {}
      @positives.each do|idx, line|
        row = line.gsub(/\s+/m, ' ').chomp.split(' ')
        sp_array[idx][0..row.length - 1] = row # Merge into existing array
      end
      sp_array.each do |h|
        seq_id = h[0]
        cut_off = h[4]
        d_value = h[8]
        sp_hash[seq_id] = [cut_off: cut_off, d_value: d_value]
        @hash.empty(sp_hash, ' analysing the signal peptide.')
      end
      return sp_hash
    end

    # Presents the signal P positives data with seq Id on onto line and the
    #   sequence on the next.
    def parse(sp_hash, orf_clean, motif)
      LOG.info { 'Extracting sequences that have at least 1 neuropeptide'\
                 ' cleavage site after the signal peptide cleavage site.' }
      sp_data = {}
      sp_hash.each do |id, h|
        current_orf = orf_clean[id].to_s.gsub('["', '').gsub('"]', '')
        cut_off     = h[0][:cut_off]
        d_value     = h[0][:d_value]
        sp_clv      = cut_off.to_i - 1
        signalp     = current_orf[0, sp_clv]
        seq_end     = current_orf[sp_clv, current_orf.length]
        if seq_end.match(/#{motif}/)
          sp_data[id + 
                  "~- S.P.=> Cleavage Site: #{sp_clv}:#{cut_off} | D-value:" \
                  " #{d_value}"] = "#{signalp}~#{seq_end}"
        end 
      end
      @hash.empty(sp_data, 
                        'There are no sequences that have a signal' \
                        ' peptide and contain the requested motif after' \
                        ' the signal peptide cleavage site.')
      return sp_data
    end

    # With transcriptome data, alternative splicing means duplicates ORF, so
    #   this method collapses duplicates into one reading.
    def flattener(sp_data)
      LOG.info { 'Removing all duplicate entries.' }
      flattened_seq = {}
      sp_data.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id
      end
      @hash.empty(flattened_seq, 
                        'There was a critical error in removing' \
                        ' duplicates in the output file.')
      return flattened_seq.invert # Inverting necessary for outputting.
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

    def make_html_hash(hash, motif)
      doc_hash = {}
      hash.each do |id, seq|
        id, id_end = id.split('~').map(&:strip)
        signalp, seq_end = seq.split('~').map(&:strip)
        seq = seq_end.gsub('C', '<span class="cysteine">C</span>')\
        .gsub(/#{motif}/, '<span class="motif">\0</span>')\
        .gsub('G<span class="motif">', \
              '<span class="glycine">G</span><span class="motif">')\
        .gsub('<span class="glycine">G</span><span class="motif">KR', \
          '<span class="gkr">GKR')
        doc_hash[id] = [id_end: id_end, signalp: signalp, seq: seq]
      end
      return doc_hash
    end

    def to_html(doc_hash, output)
haml_doc = <<EOT
!!!
%html
  %head
    %title Results
    %meta{"http-equiv" => "Content-Type", :content => "text/html; charset=utf-8"}
    :css
      .id {font-weight: bold;}
      .signalp {color:#007AC0; font-weight: bold;}
      .motif {color:#00B050; font-weight: bold;}
      .glycine {color:#FFC000; font-weight: bold;}
      .phenylalanine {color:#FF00EB; font-weight: bold;}
      .gkr {color:#FF0000; font-weight: bold;}
      .cysteine {color:#00B050;}
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