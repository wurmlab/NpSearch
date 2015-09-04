require 'slim'

module NpSearch
  # Class that generates the output
  class Output
    class << self
      def to_html(input_file)
        output_file = "#{input_file}.out.html"
        templates_path = File.expand_path(File.join(__FILE__, '../../../',
                                                    'templates/contents.slim'))
        contents_temp = File.read(templates_path)
        html_content = Slim::Template.new { contents_temp }.render(NpSearch)
        File.open(output_file, 'w') { |f| f.puts html_content }
      end

      def to_fasta(input_file, sorted_sequences)
        output_file = "#{input_file}.out.fa"
        File.open(output_file, 'w') do |f|
          sorted_sequences.each do |s|
            f.puts ">#{s.id}_f#{s.translated_frame}\n#{s.seq}"
          end
        end
      end
    end
  end
end
