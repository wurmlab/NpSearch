require 'logger'

LOG = Logger.new(STDOUT)
LOG.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
end
LOG.level = Logger::FATAL # set to only show no messages

module NpSearch
  class ArgValidators
    # Changes the logger level to output extra info when the verbose option is
    #   true
    def initialize(verbose_opt, help_banner)
      LOG.level = Logger::INFO if verbose_opt.to_s == 'true'
      @help_banner = help_banner
    end


    # Ensures that the compulsory input arguments are supplied.
    def arg(motif, input_type, input, output_dir, orf_min_length, extract_orf, 
            signalp_file)
      comp_arg(motif, 'Query Motif ("-m" option)') unless extract_orf == TRUE
      comp_arg(input_type, 'Input Type ("-t" option)')
      comp_arg(input, 'Input file ("-i option")')
      comp_arg(output_dir, 'Output Folder ("-o" option)')
      if input == nil || input_type == nil || motif == nil || output_dir == nil
        puts @help_banner
        exit
      end
      input_file(input)
      input_type(input_type)
      orf_min_length(orf_min_length)
      extract_orf_conflict(input_type, extract_orf)
      input_sp_file_conflict(input_type, signalp_file)
    end

    # Ensures that the compulsory input arguments are not empty. 
    def comp_arg(arg, message)
      if arg == nil
        puts 'Usage Error: No ' + message + ' is supplied'
      end
    end

    # Ensures that the ORF minimum length is a number. Any digits after the
    #   decimal place are ignored.
    def orf_min_length(orf_min_length)
      if orf_min_length.to_i < 1
        puts # a blank line
        puts 'Usage Error: The Open Reading Frames minimum length can only be' \
             ' a full integer.'
        puts @help_banner
        exit 
      end  
    end

    # Ensures that the input_type has been provided in the correct format (i.e.
    #   that it is either 'genetic' or 'protein').
    def input_type(input_type)
      unless input_type.downcase == 'genetic' ||
             input_type.downcase == 'protein'
        puts # a blank line
        puts "Usage Error: The input_type: '#{input_type}' is not recognised." \
             " The input_type option ('-t' option) can either be 'genetic'" \
             " or 'protein.'"
        puts @help_banner
        exit
      end
    end

    # Ensures that the extract_orf option is only used with genetic data.
    def extract_orf_conflict(input_type, extract_orf)
      if input_type == 'protein' && extract_orf == TRUE
        puts # a blank line
        puts 'Usage Error: Conflicting arguments detected - the Extract_ORF' \
             ' option (option "-e") is only available when input file' \
             ' contains genetic data.'
        puts @help_banner
        exit
      end
    end

    # Ensures that the protein data (or open reading frames) are supplied as
    #   the input file when the signal p output file is passed.
    def input_sp_file_conflict(input_type, signalp_file)
      if input_type == 'genetic' && signalp_file != nil
        puts # a blank line
        puts 'Usage Error: Conflicting arguments detected: the signalp input' \
             ' option (option "-s") is only available when input file' \
             ' contains protein data.'
        puts @help_banner
        exit
      end
    end
    
    # Ensures that the input file a) exists b) is not empty and c) is a fasta
    #   file.
    def input_file(input_file)
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
             " be in fasta format - the input file must be in fasta format."
        puts @help_banner
        exit
      end
    end

    # Adapted from 'database_formatter.rb' from sequenceserver. Checks if the
    #   character of the file is a '>'. Run from the 'input_file_vldr' method.
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

  end

  class Validators
    # Checks for the presence of the output directory; if not found, it asks
    #   3the user whether they want to create the output directory.
    def output_dir(output_dir)
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

    # Ensures that the Signal P Script is present. If not found in the home
    #   directory, it asks the user for its location.
    def sp(signalp_dir)
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

    # Ensures that the supported version of the Signal P Script has been linked
    #   to NpSearch. Run from the 'sp_version_vldr' method.
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

    # Ensures that the critical columns in the tabular results produced by the
    #   Signal P script are conserved. Run from the 'sp_version_vldr' method.
    def sp_column(input_file)
      File.open('signalp_out.txt', 'r') do |file_stream|
        secondline = file_stream.readlines[1]
        row = secondline.gsub(/\s+/m, ' ').chomp.split(' ')
        if row[1] != 'name' && row[4] != 'Ymax' && row[5] != 'pos' &&
           row[9] != 'D'
          return TRUE
        else
          return FALSE
        end
      end
    end

    # Ensure that the right version of the Signal P script is used (via
    #   'sp_version' Method). If the wrong signal p script has been linked to
    #   NpSearch, check whether the critical columns in the tabular results
    #   produced by the Signal P Script are conserved (via 'sp_column_vldr'
    #   Method).
    def sp_results(signalp_output_file)
      unless sp_version(signalp_output_file)
      # i.e. if Signal P is the wrong version
        if sp_column(signalp_output_file)
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
  end


  class Input
    # Reads the input file converting it into a hash [id => seq].
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
      if input_read.empty?
        raise IOError.new("\nCritical Error: There was an error in reading" \
                          " the input and converting it into the required" \
                          " format.\n")
      end
      return input_read
    end
  end

  class Translation
    # Translates in all 6 frames - with * standing for stop codons
    def translate(input_read)
      LOG.info { 'Step 1: Translating the genomic data in all 6 frames.' }
      protein_data = {}
      input_read.each do |id, sequence|
        (1..6).each do |f|
          protein_data[id + '_f' + f.to_s] = sequence.translate(f)
        end
      end
      if protein_data.empty?
        raise IOError.new("\nCritical Error: There was an error in" \
                          " translating input data in all 6 frames.\n")
      end
      return protein_data
    end

    # Extract all possible Open Reading Frames.
    def extract_orf(protein_data, minimum_length)
      LOG.info { 'Step 2: Extracting all Open Reading Frames from all 6 possible' \
                 ' frames. This is every methionine residue to the next stop' \
                 ' codon.' }
      orf = {}
      orf_length = minimum_length - 1 # no. of residues after 'M' 
      protein_data.each do |id, sequence|
        identified_orfs = sequence.scan(/(?=(M\w{#{orf_length},}))./)
        (0..(identified_orfs.length - 1)).each do |i|
          orf[id + '_' + i.to_s] = identified_orfs[i]
        end
      end
      if orf.empty?
        raise IOError.new("\nCritical Error: There was an error in removing " \
                          " Open Reading Frames that are smaller than the" \
                          " critical length (ORF_min_length).\n")
      end
      return orf
    end
  end

  class Signalp
    # Runs an external Signal Peptide script from CBS (Center for biological
    #   Sequence Analysis).
    def signalp(signalp_dir, input, output)
      LOG.info { "Step 3: Running a Signal Peptide test on each sequence.\nPlease be" \
                 " patient, this may take some time with large datasets." }
      exit_code = system("#{signalp_dir}/signalp -t euk -f short #{input} > " \
                         "#{output}")
      if exit_code != true
        raise IOError.new ("\nCritical Error: There seems to be a problem in" \
                           " running the external Signal P script (" \
                           " downloadable from CBS).\n")
      end
      LOG.info { "Writing the Signal Peptide test results to the file " \
                  "'#{output}'." }
    end
  end

  class Analysis
    # Extracts the rows from the tabular results produced by the Signal P
    #   script that are positive for a signal peptide.
    def extract_sp_positives(sp_out_file)
      signalp_out_file = File.read(sp_out_file)
      identified_positives = signalp_out_file.scan(/^.* Y .*$/)

      sp_array = Array.new(identified_positives.length)\
                      { Array.new(identified_positives.length, 0) }
      
      identified_positives.each_with_index do |line, idx|
        row = line.gsub(/\s+/m, ' ').chomp.split(' ')
        sp_array[idx][0..row.length - 1] = row # Merge into existing array
      end
      return sp_array
    end

    # Extracts the Sequences for each signal peptide positive sequence and the
    #   split the sequence into signal peptide and the rest of the sequence.
    def parse(sp_out_file, orf_clean, motif)
      LOG.info { 'Step 4: Extracting sequences that have at least 1 neuropeptide'\
                 ' cleavage site after the signal peptide cleavage site.' }
      sp_data  = {}
      sp_array = extract_sp_positives(sp_out_file)
      sp_array.each do |h|
        seq_id      = h[0]
        d_value     = h[8]
        cut_off     = h[4]
        sp_clv      = cut_off.to_i - 1
        current_orf = orf_clean[seq_id].to_s.gsub('["', '').gsub('"]', '')
        signalp     = current_orf[0, sp_clv]
        seq_end     = current_orf[sp_clv, current_orf.length]
        if seq_end.match(/#{motif}/)
          sp_data[seq_id + '~~~ - S.P.=> Cleavage Site: ' + sp_clv.to_s + ':' + 
                  cut_off.to_s + ' | D-value: ' + d_value.to_s] = 
                  signalp + '~~~' + seq_end
        end 
      end
      if sp_data.empty?
        raise IOError.new("\nCritical Error: No Sequences found that contain" \
                          " a secretory signal peptide as well as the" \
                          " requested motif.\n")
      end
      return sp_data
    end

    # With transcriptome data, alternative splicing means duplicates ORF, so
    #   this method collapses duplicates into one reading.
    def flattener(sp_data)
      LOG.info { 'Step 5: Removing all duplicate entries.' }
      flattened_seq = {}
      sp_data.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id
      end
      if flattened_seq.empty?
        raise IOError.new("\nCritical Error: There was a critical error in" \
                          " removing duplicate data in the output file.\n")
      end
      return flattened_seq.invert # Inverting necessary for outputting.
    end
  end

  class Output
`    # Converts a hash into a fasta file.
    def to_fasta(what, hash, output)
      LOG.info { "Writing the #{what} to the file:'#{output}'." }
      output_file = File.new(output, 'w')
      hash.each do |id, seq|
        output_file.puts '>' + id.gsub('~~~', '')
        sequence = seq.to_s.gsub('~', '').gsub('["', '').gsub('"]', '')
        output_file.puts sequence
      end
      output_file.close
    end

    # Creates a hash of variables that are required to be inputted into the
    #   HAML (HAML cannot contain any logic, so it is necessary to do all logic
    #   here).
    def make_html_hash(hash, motif)
      doc_hash = {}
      hash.each do |id, seq|
        id, id_end = id.split('~~~').map(&:strip)
        signalp, seq_end = seq.split('~~~').map(&:strip)
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

    # Converts a hash into a standalone HTML file. Hint: The standalone HTML
    #   file can be rendered and opened by Word.
    def to_html(hash, motif, output)
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
      doc_hash = make_html_hash(hash, motif)
      output_file = File.new(output, 'w')
      output_file.puts engine.render(Object.new, doc_hash: doc_hash)
      LOG.info { "Writing the final output file to the file:'#{output}'." }
      output_file.close
    end
  end
end