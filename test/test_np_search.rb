### TO BE UPDATE with 1.2 update...

# require 'coveralls'
# Coveralls.wear!

# require 'bio'
# require 'test/unit'

# require 'npsearch'
# require 'npsearch/arg_validator'

# class InputChanged
#   # Changed to include the full entry definition rather than just the id. This
#   # was necessary for when testing individual parts since this is changed in
#   # pipeline
#   def read(input_file)
#     input_read = {}
#     biofastafile = Bio::FlatFile.open(Bio::FastaFormat, input_file)
#     biofastafile.each_entry do |entry|
#       # entry.definition used instead of entry.id
#       input_read[entry.definition] = entry.seq
#     end
#     input_read
#   end
# end

# class UnitTests < Test::Unit::TestCase
#   def setup # read all expected files
#     @dir                  = 'test/files'
#     @translation_test     = NpSearch::Translation.new
#     @analysis_test        = NpSearch::Analysis.new
#     @test_input1          = InputChanged.new
#     @test_arg_vldr        = NpSearch::ArgValidators.new(:is_verbose)
#     @test_vldr            = NpSearch::Validators.new
#     @test_input_read      = NpSearch::Input.read("#{@dir}/genetic.fa")
#     @expected_translation = NpSearch::Input.read("#{@dir}/1_protein.fa")
#     @expected_orf         = NpSearch::Input.read("#{@dir}/2_orf.fa")
#     @expected_sp_out_file = File.read("#{@dir}/3_signalp_out.txt")
#     @expected_secretome   = @test_input1.read("#{@dir}/4_secretome.fa")
#     @expected_output      = @test_input1.read("#{@dir}/5_output.fa")
#     @motif                = 'KK|KR|RR|R..R|R....R|R......R|' \
#                             'H..R|H....R|H......R|K..R|K....R|K......R'
#     @motif_ar             = %w(KR Kr kr)
#     @input_file_ar        = ["#{@dir}/genetic.fa", "#{@dir}/protein.fa"]
#     @input_file_ar_neg    = ["#{@dir}/empty_file.fa",
#                              "#{@dir}/missing_input.fa", "#{@dir}/not_fasta.fa"]
#     @cut_off_ar           = [622, 10, 2, 1]
#     @cut_off_ar_neg       = [-10, 'hello', -5, 0]
#   end

#   def test_motif
#     (0..2).each do |i|
#       test_run = @test_arg_vldr.arg(@motif_ar[i], @input_file_ar[0], @dir,
#                                     @cut_off_ar[0], FALSE, nil, 'help_banner')
#       assert_equal('genetic', test_run)
#     end
#   end

#   def test_input_file
#     test_run = @test_arg_vldr.arg(@motif_ar[0], @input_file_ar[0], @dir,
#                                   @cut_off_ar[0], FALSE, nil, 'help_banner')
#     assert_equal('genetic', test_run)
#     test_run1 = @test_arg_vldr.arg(@motif_ar[0], @input_file_ar[1], @dir,
#                                    @cut_off_ar[0], FALSE, nil, 'help_banner')
#     assert_equal('protein', test_run1)
#     (0..2).each do |i|
#       test_run2 = lambda do
#         @test_arg_vldr.arg(@motif_ar[0], @input_file_ar_neg[i], @dir,
#                            @cut_off_ar[0], FALSE, nil, 'help_banner')
#       end
#       assert_raise(ArgumentError) { test_run2 }
#     end
#   end

#   def test_orf_min_length
#     (0..3).each do |i|
#       test_run = @test_arg_vldr.arg(@motif_ar[0], @input_file_ar[0], @dir,
#                                     @cut_off_ar[i], FALSE, nil, 'help_banner')
#       assert_equal('genetic', test_run)
#     end
#     (0..3).each do |i|
#       test_run1 = lambda do
#         @test_arg_vldr.arg(@motif_ar[0], @input_file_ar[0], @dir,
#                            @cut_off_ar_neg[i], FALSE, nil, 'help_banner')
#       end
#       assert_raise(ArgumentError) { test_run1 }
#     end
#   end

#   # => Test if the output directory validator works, in ensuring whether an
#   #    output directory can be found.
#   def test_output_dir_validator
#     assert_equal(nil, @test_vldr.output_dir(@dir))
#   end

#   # => Test if the translation method works properly - assert that the produced
#   #    translation is equal to the expected translation hash
#   def test_translate
#     translation_hash_test = NpSearch::Translation.translate(@test_input_read)
#     assert_equal(@expected_translation, translation_hash_test)
#   end

#   # => Test if the extract_orf method works properly - assert that the produced
#   #    orf hash is equal to the expected orf hash.
#   # => In orf method, an array is produced while in the expected file read, an
#   #    array isn't produced, thus it s necessary to remove "[  ]" from both end.
#   def test_extract_orf
#     orf_hash_test = NpSearch::Translation.extract_orf(@expected_translation, 10)
#     assert_equal(@expected_orf.to_s, orf_hash_test.to_s.gsub('["', '"')
#                                                        .gsub('"]', '"'))
#   end

#   def test_parse
#     secretome = NpSearch::Analysis.parse("#{@dir}/3_signalp_out.txt",
#                                          @expected_orf, @motif)
#     assert_equal(@expected_secretome, secretome)
#   end

#   def test_flattener
#     flattened_output_test = NpSearch::Analysis.flattener(@expected_secretome)
#     assert_equal(@expected_output, flattened_output_test)
#   end
# end
