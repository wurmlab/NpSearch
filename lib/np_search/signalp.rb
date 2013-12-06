module NpSearchSignalP
class Signalp
    @positives = nil

    # Runs an external Signal Peptide script from CBS.
    def signal_p(signalp_dir, input, output)
      system("#{signalp_dir}/signalp -t euk -f short #{input} > #{output}")
    end

    # Creates a signalp positives file, if required.
    def signalp_positives_file_writer(input, identified_positives, output)
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
      signalp_with_seq = {}
      signalp_hash.each do |id, h|
        current_orf = orf_clean[id].to_s.gsub('["', '').gsub('"]', '')
        cut_off     = h[0][:cut_off]
        d_value     = h[0][:d_value]
        sp_clv      = cut_off.to_i - 1
        signalp     = current_orf[0, sp_clv]
        seq_end     = current_orf[sp_clv, current_orf.length]
        if seq_end.match(/#{motif}/)
          signalp_with_seq[id + "~- S.P.=> Cleavage Site: #{sp_clv}:#{cut_off}"\
                           " // D-value: #{d_value}"] = "#{signalp}~#{seq_end}"
        end 
      end
      return signalp_with_seq
    end

    # With transcriptome data, alternative splicing means duplicates ORF, so
    #   this method collapses duplicates into one reading.
    def flattener(signalp_with_seq)
      flattened_seq = {}
      signalp_with_seq.each do |id, seq|
        flattened_seq[seq] = [] unless flattened_seq[seq]
        flattened_seq[seq] = id
      end
      return flattened_seq.invert # Format required for the outputting.
    end
  end
end