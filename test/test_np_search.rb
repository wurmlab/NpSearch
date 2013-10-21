#!/usr/bin/env ruby

require 'bio'
require './../lib/np_search/library.rb'
require 'test/unit'

class InputChanged 
#changed to include the full entry definition rather than just the id. This necessary for when testing individual parts since this is changed in pipeline...
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
    test_input                   = NpSearch::Input.new
    @test_genetic_input_read     = test_input.read("./test_inputs/genetic.fa", "genetic")
    @expected_translation_hash   = test_input.read("./test_files/protein.fa", "protein")
    @expected_orf_hash           = test_input.read("./test_files/orf.fa", "protein")
    @expected_orf_condensed_hash = test_input.read("./test_files/orf_condensed.fa", "protein")    
    @expected_signalp_file       = File.read("./test_files/signalp_out.txt")
    test_input1                  = InputChanged.new
    @expected_signalp_with_seq   = test_input1.read("./test_files/signalp_with_seq.fa", "protein")
    @expected_flattened_output   = test_input1.read("./test_files/output.fa", "protein")
    @expected_positives_number   = 10
    @motif                       = "KK|KR|RR|R..R|R....R|R......R|H..R|H....R|H......R|K..R|K....R|K......R|GK|L"
  end
  
  ####### Testing input for normal & weird cases ####### => commented out since it uses absolute directories
# => Test if the signalp validator method works in verifying whether the directory contains the signal p script. 
#  def test_signalp_validator
#    test_validators = NpSearch::InputValidators.new
#    assert_equal("./../../../signalp", test_validators.signalp_validator("./../../../signalp"))
#  end

# => Test if the output directory validator works, in ensuring whether an output directory can be found. 
  def test_output_dir_validator
    test_validators = NpSearch::InputValidators.new
    assert_equal(nil, test_validators.output_dir_validator("./test_out"))
  end

# => Test if the orf_min_length validator works, in ensuring that the value is number
  def test_orf_min_length_validator
    test_validators = NpSearch::InputValidators.new
    assert_equal(nil, test_validators.orf_min_length_validator("622"))
    assert_equal(nil, test_validators.orf_min_length_validator("10"))
    assert_equal(nil, test_validators.orf_min_length_validator("2.567"))
    assert_equal(nil, test_validators.orf_min_length_validator("2"))
    assert_equal(nil, test_validators.orf_min_length_validator("1"))
    assert_raise( SystemExit ) {test_validators.orf_min_length_validator("0")}
    assert_raise( SystemExit ) {test_validators.orf_min_length_validator("-5")}
  end

# => Test if the input_file_validator works properly, in ensuring that input file is not missing, empty or is in the wrong format. 
  def test_input_file_validator_1
    test_validators = NpSearch::InputValidators.new
    assert_equal(nil, test_validators.input_file_validator("./test_inputs/genetic.fa"))
    assert_equal(nil, test_validators.input_file_validator("./test_inputs/protein.fa"))
    assert_raise( SystemExit ) {test_validators.input_file_validator("./test_inputs/missing_input.fa")}
    assert_raise( SystemExit ) {test_validators.input_file_validator("./test_inputs/empty_file.fa")}
    assert_raise( SystemExit ) {test_validators.input_file_validator("./test_inputs/missing_input.fa")}
    assert_raise( SystemExit ) {test_validators.input_file_validator("./test_inputs/not_fasta.fa")}
  end

# => Test if the probably_fasta method works in ensuring that the input file is in the fasta format.
  def test_probably_fasta
    test_validators = NpSearch::InputValidators.new
    assert_equal(TRUE, test_validators.probably_fasta("./test_inputs/genetic.fa"))
    assert_equal(TRUE, test_validators.probably_fasta("./test_inputs/protein.fa"))
    assert_equal(FALSE, test_validators.probably_fasta("./test_inputs/not_fasta.fa"))
  end

# => Test if the input type validator works properly in that only the recognised formats can be used.
  def test_input_type_validator
    test_validators = NpSearch::InputValidators.new
    assert_equal(nil, test_validators.input_type_validator("genetic"))
    assert_equal(nil, test_validators.input_type_validator("GENETIC"))
    assert_equal(nil, test_validators.input_type_validator("Genetic"))
    assert_equal(nil, test_validators.input_type_validator("geNETic"))
    assert_equal(nil, test_validators.input_type_validator("protein"))
    assert_equal(nil, test_validators.input_type_validator("Protein"))
    assert_equal(nil, test_validators.input_type_validator("prOTEin"))
    assert_raise( SystemExit ) {test_validators.input_type_validator("JUNK")}
    assert_raise( SystemExit ) {test_validators.input_type_validator("sdaBVHJHKipu;i")}
    assert_raise( SystemExit ) {test_validators.input_type_validator("SDFVDhqgvCDCDSCbnw")}
  end

  ####### Testing individual parts of the script ####### 
# => Test if the translation method works properly - assert that the produced translation is equal to the expected translation hash 
  def test_translate()
    translation_test = NpSearch::Translation.new
    translation_hash_test = translation_test.translate(@test_genetic_input_read)
    assert_equal(@expected_translation_hash , translation_hash_test)
  end

# => Test if the extract_orf method works properly - assert that the produced orf hash is equal to the expected orf hash.
  def test_extract_orf()
    translation_test = NpSearch::Translation.new
    orf_hash_test = translation_test.extract_orf(@expected_translation_hash)
    assert_equal(@expected_orf_hash.to_s, orf_hash_test.to_s.gsub("[", "").gsub("]", "")) #in orf method, an array is produced while in the expected file read, an array isn't produced, thus it s necessary to remove "[  ]" from either end.
  end   

# => Test if the orf cleaner method works properly - assert that the produced orf_cleaer hash is equal to the expected hash.
  def test_orf_cleaner()
    translation_test = NpSearch::Translation.new
    orf_condensed_hash_test = translation_test.orf_cleaner(@expected_orf_hash, (10 - 4)) 
    assert_equal(@expected_orf_condensed_hash, orf_condensed_hash_test)
  end

# => Test if the external signal p script runs correctly and produces the expected results - asserts that the produced sigalp p output file is identical to the expected file.w
  def test_signalp() # external script
    signalp_dir = "./../../../signalp"
    signalp_test = NpSearch::Signalp.new
    signalp_test.signal_p(signalp_dir, "./test_files/orf_condensed.fa", "./test_out/signalp_out.txt")
    test_signalp_file = File.read("./test_out/signalp_out.txt")
    assert_equal(@expected_signalp_file, test_signalp_file)
  end

# => Tests that the signalp positives extractor methods works properly - asserts that the produced signalp_positives hash is identical to the expected result. 
  def test_signalp_positives_extractor()
    signalp_test = NpSearch::Signalp.new
    @test_positives_number = signalp_test.signalp_positives_extractor("./test_out/signalp_out.txt").to_i
    assert_equal(@expected_positives_number, @test_positives_number)
  end

# => Tests that the parsing method works properly - asserts that the produced signalp_positives_with_seq hash is identical to the expected result. 
  def test_parse()
    signalp_test = NpSearch::Signalp.new
    test_positives_number = signalp_test.signalp_positives_extractor("./test_out/signalp_out.txt").to_i
    signalp = signalp_test.array_generator(@expected_positives_number.to_i)
    signalp_with_seq_test = signalp_test.parse(signalp, @expected_orf_condensed_hash, @motif)
    assert_equal(@expected_signalp_with_seq, signalp_with_seq_test)
  end

# => Tests that the flattener method works properly - asserts that the produced flattened results is identical to the excpected results.
  def test_flattener()
    signalp_test = NpSearch::Signalp.new
    flattened_output_test = signalp_test.flattener(@expected_signalp_with_seq)
    assert_equal(@expected_flattened_output, flattened_output_test)
  end
end