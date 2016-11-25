require_relative 'test_helper'
require 'npsearch'
require 'npsearch/arg_validator'

# Class to test the how well the CLI arguments are validated.
class TestInputArgumentValidator < Minitest::Test
  def setup
    NpSearch.logger = Logger.new(STDOUT, true)
    @c = NpSearch::ArgumentsValidators
    @opt = { num_threads: 1, min_orf_length: 30, debug: true }
  end

  def test_assert_file_present
    @c.send(:assert_file_present, 'existing file',
            'test/files/genetic.fa', 1)
    assert_raises(SystemExit) do
      @c.send(:assert_file_present, 'non-existing file',
              'test/files/nope_dont_exist.fa', 1)
    end
  end

  def test_assert_input_file_not_empty
    f = 'test/files/genetic.fa'
    @c.send(:assert_input_file_not_empty, f)
    f = 'test/files/empty_file.fa'
    assert_raises(SystemExit) { @c.send(:assert_input_file_not_empty, f) }
  end

  def test_assert_input_file_probably_fasta
    f = 'test/files/genetic.fa'
    @c.send(:assert_input_file_probably_fasta, f)
    f = 'test/files/not_fasta.fa'
    assert_raises(SystemExit) { @c.send(:assert_input_file_probably_fasta, f) }
  end

  def test_assert_input_sequence
    f = 'test/files/genetic.fa'
    @c.send(:assert_input_sequence, f)
    f = 'test/files/protein.fa'
    @c.send(:assert_input_sequence, f)
    f = 'test/files/mixed_content.fa'
    assert_raises(SystemExit) { @c.send(:assert_input_sequence, f) }
  end

  def test_check_num_threads
    [1, 50, 300].each do |t|
      @c.send(:check_num_threads, t)
    end
    assert_equal(1, @c.send(:check_num_threads, -3))
  end
end
