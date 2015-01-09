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
      input_read
    end
  end


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
      protein_data
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
      orf
    end
  end


  class Signalp
    # Runs an external Signal Peptide script from CBS (Center for biological
    #   Sequence Analysis).
    def self.signalp(signalp_dir, input, output)
      LOG.info { "Running a Signal Peptide test on each sequence.\n" \
                 "                           This may take some time with" \
                 " large datasets." }
      d_value = '-U 0.34 -u 0.34' : ''
      exit_code = system("#{signalp_dir}/signalp -t euk -f short #{d_value}" \
                         "  #{input} > #{output}")
      if exit_code != true
        raise IOError('Critical Error: There seems to be a problem in running' \
                      ' the external Signal P script (downloadable from CBS).')
      end
      LOG.info { "Writing the Signal Peptide test results to the file" \
                 " '#{output}'." }
    end
  end


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
      sp_array
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
      sp_data
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
      flattened_seq.invert # Inverting necessary for outputting.
    end
  end
end


class Hash
  # Converts a hash into a fasta file.
  def to_fasta(what, output)
    LOG.info { "Writing the #{what} to the file:'#{output}'." }
    output_file = File.new(output, 'w')
    each do |id, seq|
      output_file.puts '>' + id.gsub('~~~', '')
      sequence = seq.to_s.gsub(/[\[\"\~\]]/, '')
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
    doc_hash
  end
end


class File
  # Checks if the first character of the file is a '>'.
  def self.probably_fasta?(input_file)
    open(input_file, 'r') do |file_stream|
      return (file_stream.readline[0] == '>') ? true : false
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