require_relative 'test_helper'

require 'npsearch/sequence'
require 'npsearch/scoresequence'

# A class to test the ScoreSequence Class
class TestScoreSequences < Minitest::Test
  def setup
    seq = ">test_sequences\n" \
          "MFYFESFGRMWLVVCLLNSAFLTTVISGQADNTRAEVLSNAEIADEEAKELIDNLIKSKKDYS\n" \
          "SSDDDLYQMNEEDKRGLFPTGGMDPLGASYFTGKRGADSNEEETTDKRGFPNSRLDTLGSRYF\n" \
          "NGKRGFPNSGGLDTLGSRYFNGKRGFPSSGGMDTLGSGYFNGKRAFPSSGGMDTLGSRYFNGK\n" \
          "RAFPNSGGMDTLGSRYFNGKRGFPGSGGMDVLGSRYFNGKRGFPSSGGMDTLGSSYFNGKRGF\n" \
          "PSSGGMDTLGSGYFNGKRGFPNSGGMDTLGASYFTGKRGFPSSGGLDTLGSRYFNGKRGFPNS\n" \
          'GGMDTLGGRYFNGKRAIFDDFDQTDSLHGLKKGSSFLHGGLSSGGRVPGMKKRSVSSEENATE'
    sequence = Bio::FastaFormat.new(seq)
    sp = { ymax_pos: '31' }
    @seq = NpSearch::Sequence.new(sequence.entry_id, sequence.aaseq, sp, 2)
    @c = NpSearch::ScoreSequence
    @c.send(:split_into_neuropeptides, @seq)
  end

  def test_split_into_neuropeptides
    nps = [{ di_clv_st: nil, mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'DNTRAEVLSNAEIADEEAKELIDNLIKS',
             di_clv_end: 'KK', mono_2_clv_end: nil, mono_4_clv_end: nil,
             mono_6_clv_end: nil },
           { di_clv_st: 'KK', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'DYSSSDDDLYQMNEED', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GLFPTGGMDPLGASYFTG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GADSNEEETTD', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPNS', di_clv_end: nil,
             mono_2_clv_end: nil, mono_4_clv_end: nil,
             mono_6_clv_end: 'RLDTLGSR' },
           { di_clv_st: nil, mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: 'KRGFPNSR', np: 'LDTLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPNSGGLDTLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPSSGGMDTLGSGYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'AFPSSGGMDTLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'AFPNSGGMDTLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPGSGGMDVLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPSSGGMDTLGSSYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPSSGGMDTLGSGYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPNSGGMDTLGASYFTG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPSSGGLDTLGSRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GFPNSGGMDTLGGRYFNG', di_clv_end: 'KR',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KR', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'AIFDDFDQTDSLHGL', di_clv_end: 'KK',
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil },
           { di_clv_st: 'KK', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'GSSFLHGGLSSGG', di_clv_end: nil,
             mono_2_clv_end: nil, mono_4_clv_end: nil,
             mono_6_clv_end: 'RVPGMKKR' },
           { di_clv_st: 'KK', mono_2_clv_st: nil, mono_4_clv_st: nil,
             mono_6_clv_st: nil, np: 'RSVSSEENATE', di_clv_end: nil,
             mono_2_clv_end: nil, mono_4_clv_end: nil, mono_6_clv_end: nil
           }
          ]
    assert_equal(nps, @seq.potential_cleaved_nps)
  end

  def test_count_np_cleavage_sites
    @seq.score = 0
    @c.send(:count_np_cleavage_sites, @seq)
    assert_equal(1.4000000000000001, @seq.score)
  end

  def test_count_c_terminal_glycines
    @seq.score = 0
    @c.send(:count_c_terminal_glycines, @seq)
    assert_equal(3.1, @seq.score)
  end

  def test_np_similarity
    @seq.score = 0
    uclust_output = <<EOS
S 0 18  * . * * * seq6  *
H 0 18  83.3  . 0 0 18M seq8  seq6
H 0 18  83.3  . 0 0 18M seq10 seq6
S 1 16  * . * * * seq1  *
S 2 18  * . * * * seq2  *
S 3 15  * . * * * seq16 *
S 4 5 * . * * * seq4  *
H 0 18  83.3  . 0 0 18M seq11 seq6
H 0 18  94.4  . 0 0 18M seq14 seq6
H 0 18  88.9  . 0 0 18M seq15 seq6
S 5 11  * . * * * seq5  *
H 0 18  77.8  . 0 0 18M seq13 seq6
H 0 18  88.9  . 0 0 18M seq9  seq6
S 6 11  * . * * * seq18 *
S 7 28  * . * * * seq0  *
S 8 11  * . * * * seq3  *
H 0 18  83.3  . 0 0 18M seq7  seq6
H 0 18  83.3  . 0 0 18M seq12 seq6
S 9 13  * . * * * seq17 *
C 0 10  * * * * * seq6  *
C 1 1 * * * * * seq1  *
C 2 1 * * * * * seq2  *
C 3 1 * * * * * seq16 *
C 4 1 * * * * * seq4  *
C 5 1 * * * * * seq5  *
C 6 1 * * * * * seq18 *
C 7 1 * * * * * seq0  *
C 8 1 * * * * * seq3  *
C 9 1 * * * * * seq17 *
EOS
    temp_dir = File.join(Dir.pwd, '.temp')
    @c.send(:np_similarity, @seq, temp_dir, nil, uclust_output)
    assert_equal(1.5, @seq.score)
  end

  def test_acidic_spacers
    @seq.score = 0
    @c.send(:acidic_spacers, @seq)
    assert_equal(0, @seq.score)
  end
end
