#!/usr/bin/env ruby

require 'bio'
require 'np_search'
require 'test/unit'

class InputChanged 
# Changed to include the full entry definition rather than just the id. This 
#   was necessary for when testing individual parts since this is changed in 
#   pipeline...
  def read(input_file, type)
    input_read = Hash.new
    biofastafile = Bio::FlatFile.open(Bio::FastaFormat, input_file) 
    biofastafile.each_entry do |entry|
      input_read[entry.definition] = entry.aaseq ## entry.definition instead of entry.id 
    end
    return input_read
  end
end

class UnitTests < Test::Unit::TestCase
  def setup # read all expected files
    @test_input                 = NpSearch::Input.new
    @test_input1                = InputChanged.new
    @test_arg_vldr              = NpSearch::ArgValidators.new(:is_verbose, 'Help Banner')
    @test_vldr                  = NpSearch::Validators.new
    @translation_test           = NpSearch::Translation.new
    @analysis_test              = NpSearch::Analysis.new
    @test_genetic_input_read    = @test_input.read("test/test_inputs/genetic.fa", "genetic")
    @expected_translation_hash  = @test_input.read("test/test_files/protein.fa", "protein")
    @expected_orf_clean_hash    = @test_input.read("test/test_files/orf_clean.fa", "protein")    
    @expected_signalp_file      = File.read("test/test_files/signalp_out.txt")
    @expected_output            = @test_input1.read("test/test_files/output.fa", "protein")
    @expected_positives_number  = 10
    @motif                      = "KK|KR|RR|R..R|R....R|R......R|H..R|H....R|H......R|K..R|K....R|K......R|GK|L"
  
    @motif_array                = ['KR', 'Kr', 'kr']
    @input_type_array           = ['genetic', 'GENETIC', 'Genetic', 'GenETIc', 'protein', 'Protein', 'PrOTein']
    @input_type_array_negatives = ['protein', 'JUNK', 'asggbfdvac', 'qefr4gwtvwgbr'] # first genetic conflicts with -e option...
    @input_file_array           = ["test/test_inputs/genetic.fa", "test/test_inputs/protein.fa"]
    @input_file_array_negatives = ["test/test_inputs/empty_file.fa", "test/test_inputs/missing_input.fa", "test/test_inputs/not_fasta.fa"]
    @cut_off_array              = [622, 10, 2 , 1]
    @cut_off_array_negative     = [-10, 'hello', -5, 0 ]
  end

  def test_motif
    (0..2).each do |i|
      assert_equal(nil, @test_arg_vldr.arg(@motif_array[i], @input_type_array[0], @input_file_array[0], "test/test_out", @cut_off_array[0], FALSE, nil))
    end
  end


  def test_input_type
    (0..6).each do |i|
      assert_equal(nil, @test_arg_vldr.arg(@motif_array[0], @input_type_array[i], @input_file_array[0], "test/test_out", @cut_off_array[0], FALSE, nil))
    end
    (0..3).each do |i|
      assert_raise( SystemExit ) {@test_arg_vldr.arg(@motif_array[0], @input_type_array_negatives[i], @input_file_array[0], "test/test_out", @cut_off_array[0], TRUE, nil)}
    end
  end

  def test_input_file
    (0..1).each do |i|
      assert_equal(nil, @test_arg_vldr.arg(@motif_array[0], @input_type_array[0], @input_file_array[i], "test/test_out", @cut_off_array[0], FALSE, nil))
    end
    (0..2).each do |i|
      assert_raise( SystemExit ) {@test_arg_vldr.arg(@motif_array[0], @input_type_array[0], @input_file_array_negatives[i], "test/test_out", @cut_off_array[0], FALSE, nil)}
    end
  end

  def orf_min_length
    (0..3).each do |i|
      assert_equal(nil, @test_arg_vldr.arg(@motif_array[0], @input_type_array[0], @input_file_array[0], "test/test_out", @cut_off_array[i], FALSE, nil))
    end
    (0..3).each do |i|
      assert_raise( SystemExit ) {@test_arg_vldr.arg(@motif_array[0], @input_type_array[0], @input_file_array[0], "test/test_out", @cut_off_array_negative[i], FALSE, nil)}
    end
  end

=begin
  ####### Testing input for normal & weird cases
# => Test if the signalp validator method works in verifying whether the directory contains the signal p script. 
  def test_signalp_validator
    assert_equal("test/test_files/signalp", @test_validators.sp_vldr("test/test_files/signalp"))
  end

# => Test if the output directory validator works, in ensuring whether an output directory can be found. 
  def test_output_dir_validator
    assert_equal(nil, @test_validators.output_dir_vldr())
  end
=end

  ####### Testing individual parts of the script ####### 
# => Test if the translation method works properly - assert that the produced translation is equal to the expected translation hash 
  def test_translate()
    translation_hash_test = @translation_test.translate(@test_genetic_input_read)
    assert_equal(@expected_translation_hash , translation_hash_test)
  end

# => Test if the extract_orf method works properly - assert that the produced orf hash is equal to the expected orf hash.
  def test_extract_orf()
    orf_hash_test = @translation_test.extract_orf(@expected_translation_hash, 10)
    assert_equal(@expected_orf_clean_hash.to_s, orf_hash_test.to_s.gsub('[', '').gsub(']', '')) #in orf method, an array is produced while in the expected file read, an array isn't produced, thus it s necessary to remove "[  ]" from either end.
  end   

# => Test if the orf cleaner method works properly - assert that the produced orf_cleaer hash is equal to the expected hash.
  def test_orf_cleaner()
  #  orf_clean_hash_test = @translation_test.orf_cleaner(@expected_orf_hash, (10 - 4)) 
 #   assert_equal(@expected_orf_clean_hash, orf_clean_hash_test)
  end

=begin
# => Tests that the signalp positives extractor methods works properly - asserts that the produced signalp_positives hash is identical to the expected result. 
  def test_signalp_positives_extractor()
    @test_positives_number = @analysis_test.sp_positives_extractor("test/test_files/signalp_out.txt", "test/test_out/signalp_positives.txt", "sp_positives_file").to_i
    assert_equal(@expected_positives_number, @test_positives_number)
  end

# => Tests that the parsing method works properly - asserts that the produced signalp_positives_with_seq hash is identical to the expected result. 
  def test_parse()
    test_positives_number = @analysis_test.sp_positives_extractor("test/test_files/signalp_out.txt", "test/test_out/signalp_positives.txt", "syyyyp_positives_file").to_i
    signalp = @analysis_test.array_generator(@expected_positives_number.to_i)
    signalp_with_seq_test = @analysis_test.parse(signalp, @expected_orf_clean_hash, @motif)
    assert_equal(@expected_signalp_with_seq, signalp_with_seq_test)
  end

# => Tests that the flattener method works properly - asserts that the produced flattened results is identical to the excpected results.
  def test_flattener()
    flattened_output_test = @analysis_test.flattener(@expected_signalp_with_seq)
    assert_equal(@expected_flattened_output, flattened_output_test)
  end
=end
end