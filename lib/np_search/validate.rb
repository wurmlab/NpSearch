module NpSearchValidators
  class Validators
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
end