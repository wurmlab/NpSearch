require 'logger'
require 'bio'
require 'fileutils'
require 'haml'

LOG = Logger.new(STDOUT)
LOG.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{msg}\n"
end
LOG.level = Logger::FATAL # set to show no messages...

# Changes the output format of the ArgumentError: Adds an extra blank line 
#   before and after the message, making it stand out 
def ArgumentError(msg)
  raise ArgumentError, "\n\n#{msg}\n\n"
end

# Changes the output format of the IOError: Adds an extra blank line 
#   before and after the message, making it stand out 
def IOError(msg)
  raise IOError, "\n\n#{msg}\n\n"
end

module NpSearch
  class ArgValidators
    # Changes the logger level to output extra info when the verbose option is
    #   true.
    def initialize(verbose_opt)
      LOG.level = Logger::INFO if verbose_opt == true
    end

    # Runs all the arguments method...
    def arg(motif, input, output_dir, orf_min_length, extract_orf,
            signalp_file, help_banner)
      comp_arg(input, motif, output_dir, extract_orf, help_banner)
      input_type = guess_input_type(input)
      extract_orf_conflict(input_type, extract_orf)
      input_sp_file_conflict(input_type, signalp_file)
      orf_min_length(orf_min_length)
      return input_type
    end

    # Ensures that the compulsory input arguments are supplied...
    def comp_arg(input, motif, output_dir, extract_orf, help_banner)
      comp_arg_error(motif, 'Query Motif ("-m" option)') if extract_orf == false
      comp_arg_error(input, 'Input file ("-i option")')
      comp_arg_error(output_dir, 'Output Folder ("-o" option)')
      if input == nil || output_dir == nil ||
         (motif == nil && extract_orf == false)
        puts help_banner
        exit
      end
    end

    # Ensures that a message is provided for all missing compulsory args.
    #   Run from comp_arg method
    def comp_arg_error(arg, message)
      if arg == nil
        puts 'Usage Error: No ' + message + ' is supplied'
      end
    end

    # Guesses the type of data within the input file on the first 100 lines of 
    #   the file (ignores all identifiers (lines that start with a '>').
    #   It has a 80% threshold.
    def guess_input_type(input_file)
      input_file_format(input_file)
      sequences = []
      File.open(input_file, 'r') do |file_stream|
        file_stream.readlines[0..100].each do |line|
          sequences << line.to_s unless line.match(/^>/)
        end
      end
      type = Bio::Sequence.new(sequences).guess(0.8)
      if type == Bio::Sequence::NA
        input_type = 'genetic'
      elsif type == Bio::Sequence::AA
        input_type = 'protein'
      end
      return input_type
    end

    # Ensures that the input file a) exists b) is not empty and c) is a fasta
    #   file. Run from the guess_input_type method.
    def input_file_format(input_file)
      unless File.exist?(input_file)
        raise ArgumentError("Critical Error: The input file '#{input_file}'" \
                            " does not exist.")
      end
      if File.zero?(input_file)
        raise ArgumentError("Critical Error: The input file '#{input_file}'" \
                            " is empty.")
      end
      unless File.probably_fasta?(input_file)
        raise ArgumentError("Critical Error: The input file '#{input_file}'" \
                            " does not seem to be in fasta format. Only" \
                            " input files in fasta format are supported.")
      end
    end

    # Ensures that the extract_orf option is only used with genetic data.
    def extract_orf_conflict(input_type, extract_orf)
      if input_type == 'protein' && extract_orf == true
        raise ArgumentError('Usage Error: Conflicting arguments detected:' \
                            ' Protein data detected within the input file,' \
                            ' when using the  Extract_ORF option (option' \
                            ' "-e"). This option is only available when' \
                            ' input file contains genetic data.')
      end
    end

    # Ensures that the protein data (or open reading frames) are supplied as
    #   the input file when the signal p output file is passed.
    def input_sp_file_conflict(input_type, signalp_file)
      if input_type == 'genetic' && signalp_file != nil
        raise ArgumentError('Usage Error: Conflicting arguments detected' \
                            ': Genetic data detected within the input file' \
                            ' when using the Signal P Input Option (Option' \
                            ' "-s"). The Signal P input Option requires the' \
                            ' input of two files: the Signal P Script Result' \
                            ' files (at the "-s" option) and the protein' \
                            ' data file used to run the Signal P Script.')
      end
    end

    # Ensures that the ORF minimum length is a number. Any digits after the
    #   decimal place are ignored.
    def orf_min_length(orf_min_length)
      if orf_min_length.to_i < 1
        raise ArgumentError('Usage Error: The Open Reading Frames minimum' \
                            ' length can only be a full integer.')
      end
    end
  end ### End of ArgValidators Class


  class Validators
    # Checks for the presence of the output directory; if not found, it asks
    #   the user whether they want to create the output directory.
    def output_dir(output_dir)
      begin
        unless File.directory? output_dir # If output_dir doesn't exist
          raise IOError, "\n\nThe output directory deoes not exist\n\n"
        end
      rescue IOError
        puts # a blank line
        puts 'The output directory does not exist.'
        puts # a blank line
        puts "The directory '#{output_dir}' will be created in this location."
        puts 'Do you to continue? [y/n]'
        print '> '
        inp = $stdin.gets.chomp
        until inp.downcase == 'n' || inp.downcase == 'y' || inp == ''
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
        if inp.downcase == 'y' || inp == ''
          FileUtils.mkdir_p "#{output_dir}"
          puts 'Created output directory...'
        elsif inp.downcase == 'n'
          raise ArgumentError('Critical Error: An output directory is' \
                              ' required; please create an output directory' \
                              ' and then try again.')
        end
      end
    end

    # Ensures that the Signal P Script is present. If not found in the home
    #   directory, it asks the user for its location.
   def signalp_dir
      signalp_dir = "#{Dir.home}/SignalPeptide"
      if File.exist? "#{signalp_dir}/signalp"
        signalp_directory = signalp_dir
      else
        begin
          raise IOError("The Signal P Script directory cannot be found at" \
                        " the following location: '#{signalp_dir}/'.")
        rescue IOError
          puts # a blank line
          puts "Error: The Signal P Script directory cannot be found at the" \
               " following location: '#{signalp_dir}/'."
          puts # a blank line
          puts 'Please enter the full path or a relative path to the Signal' \
               ' P Script directory (i.e. to the folder containing the' \
               ' Signal P script). Refer to the online tutorial for more help'
          print '> '
          inp = $stdin.gets.chomp
          until (File.exist? "#{signalp_dir}/signalp") ||
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
          FileUtils.ln_s "#{signalp_directory}", "#{Dir.home}/SignalPeptide", 
                          :force => true
          puts # a blank line
        end
      end
      return signalp_directory
    end

    # Ensures that the supported version of the Signal P Script has been linked
    #   to NpSearch. Run from the 'sp_results' method.
    def sp_version(input_file)
      File.open(input_file, 'r') do |file_stream|
        first_line = file_stream.readline
        if first_line.match(/# SignalP-4.1/)
          return true
        else
          return false
        end
      end
    end

    # Ensures that the critical columns in the tabular results produced by the
    #   Signal P script are conserved. Run from the 'sp_results' method.
    def sp_column(input_file)
      File.open('signalp_out.txt', 'r') do |file_stream|
        secondline = file_stream.readlines[1]
        row = secondline.gsub(/\s+/m, ' ').chomp.split(' ')
        if row[1] != 'name' && row[4] != 'Ymax' && row[5] != 'pos' &&
           row[9] != 'D'
          return true
        else
          return false
        end
      end
    end

    # Ensure that the right version of the Signal P script is used (via
    #   'sp_version' Method). If the wrong signal p script has been linked to
    #   NpSearch, check whether the critical columns in the tabular results
    #   produced by the Signal P Script are conserved (via 'sp_column'
    #   Method).
    def sp_results(signalp_output_file)
      unless sp_version(signalp_output_file)
      # i.e. if Signal P is the wrong version
        if sp_column(signalp_output_file) #If wrong version but correct columns
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
          raise IOError('Critical Error: NpSearch only supports SignalP 4.1' \
                        ' (downloadable form CBS) Please ensure the version' \
                        ' of the signal p script is downloaded.')
        end
      end
    end

    # Guesses the type of the data in the supplied motif. It ignores all 
    #   non-word characters (e.g. '|' that is used for regex). It has a 90% 
    #   threshold.  
    def motif_type(motif)
      motif_seq = Bio::Sequence.new(motif.gsub(/\W/, ''))
      type = motif_seq.guess(0.9)
      if type.to_s != "Bio::Sequence::AA"
        raise IOError('Critical Error: There seems to be an error in' \
                      ' processing the motif. Please ensure that the motif' \
                      ' contains amino acid residues that you wish to search' \
                      ' for.')
      end
    end
  end ### End of Validators Class


  class Input
    # Reads the input file converting it into a hash [id => seq]. Ensures that
    #   the sequences are Bio::Sequence objects...
    def self.read(input_file, type)
      LOG.info { "Reading the Input File: #{type.capitalize} data detected." }
      input_read = {}
      biofastafile = Bio::FlatFile.open(Bio::FastaFormat, input_file)
      biofastafile.each_entry do |entry|
        input_read[entry.entry_id] = entry.naseq if type == 'genetic'
        input_read[entry.entry_id] = entry.aaseq if type == 'protein'
      end
      if input_read.empty?
        raise IOError('Critical Error: There was an error in reading the' \
                      ' input and converting it into the required format.')
      end
      return input_read
    end
  end ### End of Input Class


  class Translation
    # Translates in all 6 frames - with * standing for stop codons
    def self.translate(input_read)
      LOG.info { 'Translating the genomic data in all 6 frames.' }
      protein_data = {}
      input_read.each do |id, sequence|
        (1..6).each do |f|
          protein_data[id + '_f' + f.to_s] = sequence.translate(f)
        end
      end
      if protein_data.empty?
        raise IOError('Critical Error: There was an error in translating the' \
                      ' input data in all 6 frames.')
      end
      return protein_data
    end

    # Extract all possible Open Reading Frames.
    def self.extract_orf(protein_data, minimum_length)
      LOG.info { 'Extracting all Open Reading Frames from all 6' \
                 ' possible frames. This is every methionine residue to the' \
                 ' next stop codon.' }
      orf = {}
      orf_length = minimum_length - 1 # no. of residues after 'M'
      protein_data.each do |id, sequence|
        identified_orfs = sequence.findorfs(orf_length)
        (0..(identified_orfs.length - 1)).each do |i|
          orf[id + '_' + i.to_s] = identified_orfs[i]
        end
      end
      if orf.empty?
        raise IOError('Critical Error: There was an error in removing Open' \
                      ' Reading Frames that are smaller than the critical' \
                      ' length.')
      end
      return orf
    end
  end ### End of Translation Class


  class Signalp
    # Runs an external Signal Peptide script from CBS (Center for biological
    #   Sequence Analysis).
    def self.signalp(signalp_dir, input, output)
      LOG.info { "Running a Signal Peptide test on each sequence.\n" \
                 "                           This may take some time with" \
                 " large datasets." }
      exit_code = system("#{signalp_dir}/signalp -t euk -f short #{input} > " \
                         "#{output}")
      if exit_code != true
        raise IOError('Critical Error: There seems to be a problem in running' \
                      ' the external Signal P script (downloadable from CBS).')
      end
      LOG.info { "Writing the Signal Peptide test results to the file" \
                  " '#{output}'." }
    end
  end ### End of Signalp Class


  class Analysis
    # Extracts the rows from the tabular results produced by the Signal P script
    #   that are positive for a signal peptide. Run from the 'parse' method.
    def self.extract_sp_positives(sp_out_file)
      signalp_out_file = File.read(sp_out_file)
      identified_positives = signalp_out_file.scan(/^.* Y .*$/)
      sp_array = Array.new(identified_positives.length)\
                      { Array.new(identified_positives.length, 0) }
      identified_positives.each_with_index do |line, idx|
        row = line.gsub(/\s+/m, ' ').chomp.split(' ')
        sp_array[idx][0..row.length - 1] = row # Merge into existing array
      end
      if sp_array.empty?
        raise IOError('Critical Error: No Sequences found that contain a' \
                      ' secretory signal peptide.')
      end
      return sp_array
    end

    # Extracts the Sequences for each signal peptide positive sequence and the
    #   split the sequence into signal peptide and the rest of the sequence.
    def self.parse(sp_out_file, orf_clean, motif)
      LOG.info { 'Extracting sequences that have at least 1' \
                 ' neuropeptide cleavage site after the signal peptide' \
                 ' cleavage site.' }
      sp_data  = {}
      sp_array = extract_sp_positives(sp_out_file)
      sp_array.each do |h|
        seq_id      = h[0]
        d_value     = h[8]
        cut_off     = h[4]
        sp_clv      = cut_off.to_i - 1
        current_orf = orf_clean[seq_id].to_s.gsub(/[\[\"\]]/, '')
        signalp     = current_orf[0, sp_clv]
        seq_end     = current_orf[sp_clv, current_orf.length]
        if seq_end.match(/#{motif}/)
          sp_data[seq_id + '~~~ - S.P.=> Cleavage Site: ' +
                  sp_clv.to_s + ':' + cut_off.to_s +
                  ' | D-value: ' + d_value.to_s] = signalp + '~~~' + seq_end
        end
      end
      if sp_data.empty?
        raise IOError('Critical Error: No sequences found that contain both:' \
                      ' a secretory signal peptide as well as the requested' \
                      ' neuropeptide cleavage site.')
      end
      return sp_data
    end

    # With transcriptome data, alternative splicing means duplicates ORF, so
    #   this method collapses duplicates into one reading.
    def self.flattener(sp_data)
      LOG.info { 'Removing all duplicate entries.' }
      flattened_seq = {}
      sp_data.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id
      end
      if flattened_seq.empty?
        raise IOError('Critical Error: There was a critical error in removing' \
                      ' removing duplicate data in the output file.')
      end
      return flattened_seq.invert # Inverting necessary for outputting.
    end
  end ### End of Analysis Class
end


class Hash
  # Converts a hash into a fasta file.
  def to_fasta(what, output)
    LOG.info { "Writing the #{what} to the file:'#{output}'." }
    output_file = File.new(output, 'w')
    each do |id, seq|
      output_file.puts '>' + id.gsub('~~~', '')
      sequence = seq.to_s.gsub(/[\[\"\~]]/, '')
      output_file.puts sequence
    end
    output_file.close
  end

  # Converts a hash into a standalone HTML file. Hint: The standalone HTML
  #   file can be rendered and opened by Word.
  def to_html(motif, output)
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
    doc_hash = make_html_hash(motif)
    output_file = File.new(output, 'w')
    output_file.puts engine.render(Object.new, doc_hash: doc_hash)
    LOG.info { "Writing the final output file to the file:'#{output}'." }
    output_file.close
  end

  # Creates a hash of variables that are required to be inputted into the
  #   HAML (HAML cannot contain any logic, so it is necessary to do all logic
  #   here).
  def make_html_hash(motif)
    doc_hash = {}
    each do |id, seq|
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
end


class File
  # Checks if the first character of the file is a '>'.
  def self.probably_fasta?(input_file)
    open(input_file, 'r') do |file_stream|
      if file_stream.readline[0] == '>'
        return true
      else
        return false
      end
    end
  end
end


class Bio::Sequence::AA
  # Returns an array of all possible Open Reading Frame. Assumes that the stop 
  #   codon is characterised by a non-word character i.e. '*' (as used by the 
  #   bioruby translation function). Utilises a lookahead regex that advances 
  #   through the Bio::Sequence::AA object (or a string) by a single character
  #   at a time.
  def findorfs(minsize)
    scan(/(?=(M\w{#{minsize},}))./).flatten
  end
end