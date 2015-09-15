require_relative 'test_helper'
require 'minitest/autorun'

require 'npsearch'

# Class to test the how well the CLI arguments are validated.
class TestInputArgumentValidator < Minitest::Test
  def test_no_file_present
    opt = { num_threads: 1, min_orf_length: 30 }
    NpSearch.init(opt)
  rescue SystemExit
    error = true
    assert_equal(true, error)
  end

  def test_empty_input_file
    opt = { input_file: 'test/files/empty_file.fa', num_threads: 1,
            min_orf_length: 30 }
    NpSearch.init(opt)
  rescue SystemExit
    error = true
    assert_equal(true, error)
  end

  def test_non_fasta_file
    opt = { input_file: 'test/files/not_fasta.fa', num_threads: 1,
            min_orf_length: 30 }
    NpSearch.init(opt)
  rescue SystemExit
    error = true
    assert_equal(true, error)
  end

  def test_mixed_seqeunce_content
    opt = { input_file: 'test/files/mixed_content.fa', num_threads: 1,
            min_orf_length: 30 }
    NpSearch.init(opt)
  rescue SystemExit
    error = true
    assert_equal(true, error)
  end

  def test_string_integer_num_threads
    opt = { input_file: 'test/files/genetic.fa', num_threads: '1',
            min_orf_length: 30 }
    NpSearch.init(opt)
  rescue SystemExit
    error = true
    assert_equal(true, error)
  end
end
# Non existing Signalp path
# Non existing Usearch path
