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
  end

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
  end
end