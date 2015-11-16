require 'slim'

# Top level module / namespace.
module NpSearch
  # Class that generates the output
  class Output
    class << self
      def to_html(input_file)
        templates_path = File.expand_path(File.join(__FILE__, '../../../',
                                                    'templates/contents.slim'))
        contents_temp = File.read(templates_path)
        h_content = Slim::Template.new { contents_temp }.render(NpSearch)
        File.open("#{input_file}.npsearch.html", 'w') { |f| f.puts h_content }
      end

      def to_fasta(input_file, sorted_sequences, input_type)
        File.open("#{input_file}.npsearch.fa", 'w') do |f|
          sorted_sequences.each do |s|
            if input_type == :protein
              f.puts ">#{s.defline}\n#{s.signalp}#{s.seq}"
            elsif input_type == :nucleotide
              f.puts ">#{s.defline}-(frame:#{s.translated_frame})"
              f.puts "#{s.signalp}#{s.seq}"
            end
          end
        end
      end
    end
  end
end
