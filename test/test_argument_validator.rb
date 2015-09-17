require_relative 'test_helper'
require 'minitest/autorun'

require 'npsearch/arg_validator'

# Class to test the how well the CLI arguments are validated.
class TestInputArgumentValidator < Minitest::Test
  def setup
    @c = NpSearch::ArgumentsValidators
    @opt = { num_threads: 1, min_orf_length: 30 }
  end

  def test_assert_file_present
    @c.send(:assert_file_present, 'existing file',
            'test/files/genetic.fa', 1)
    assert_raises(SystemExit) do
      @c.send(:assert_file_present, 'non-existing file',
              'test/files/nope_dont_exist.fa', 1)
    end
  end

  # def test_assert_input_file_not_empty
  #   @opt[:input_file] = 'test/files/genetic.fa'
  #   @c.send(:assert_input_file_not_empty, @opt)
  #   @opt[:input_file] = 'test/files/empty_file.fa'
  #   assert_raises(SystemExit) { @c.send(:assert_input_file_not_empty) }
  # end

  # def test_no_file_present
  #   opt = { }
  #   NpSearch.init(opt)
  # rescue SystemExit
  #   error = true
  #   assert_equal(true, error)
  # end

  # def test_empty_input_file
  #   opt = { input_file: 'test/files/empty_file.fa', num_threads: 1,
  #           min_orf_length: 30 }
  #   NpSearch.init(opt)
  # rescue SystemExit
  #   error = true
  #   assert_equal(true, error)
  # end

  # def test_non_fasta_file
  #   opt = { input_file: 'test/files/not_fasta.fa', num_threads: 1,
  #           min_orf_length: 30 }
  #   NpSearch.init(opt)
  # rescue SystemExit
  #   error = true
  #   assert_equal(true, error)
  # end

  # def test_mixed_seqeunce_content
  #   opt = { input_file: 'test/files/mixed_content.fa', num_threads: 1,
  #           min_orf_length: 30 }
  #   NpSearch.init(opt)
  # rescue SystemExit
  #   error = true
  #   assert_equal(true, error)
  # end

  # def test_string_integer_num_threads
  #   opt = { input_file: 'test/files/genetic.fa', num_threads: '1',
  #           min_orf_length: 30 }
  #   NpSearch.init(opt)
  # rescue SystemExit
  #   error = true
  #   assert_equal(true, error)
  # end
end
# Non existing Signalp path
# Non existing Usearch path
