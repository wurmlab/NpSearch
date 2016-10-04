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
    sp = { ymax_pos: '31', orf: sequence.seq }
    @seq = NpSearch::Sequence.new(sequence, sp, 2)
    @c = NpSearch::ScoreSequence
    @c.send(:split_into_potential_neuropeptides, @seq)
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
    cdhit_output = <<EOS
>Cluster 0
0 28aa, >seq0... *
>Cluster 1
0 18aa, >seq2... *
1 18aa, >seq13... at 72.22%
>Cluster 2
0 5aa, >seq4... at 100.00%
1 11aa, >seq5... at 100.00%
2 18aa, >seq6... *
3 18aa, >seq7... at 83.33%
4 18aa, >seq8... at 83.33%
5 18aa, >seq9... at 88.89%
6 18aa, >seq10... at 83.33%
7 18aa, >seq11... at 83.33%
8 18aa, >seq12... at 83.33%
9 18aa, >seq14... at 94.44%
10  18aa, >seq15... at 88.89%
>Cluster 3
0 16aa, >seq1... *
>Cluster 4
0 15aa, >seq16... *
>Cluster 5
0 13aa, >seq17... *
>Cluster 6
0 11aa, >seq3... *
>Cluster 7
0 11aa, >seq18... *
EOS
    temp_dir = File.join(Dir.pwd, '.temp')
    @c.send(:np_similarity, @seq, temp_dir, cdhit_output)
    assert_equal(1.95, @seq.score)
  end

  def test_acidic_spacers
    @seq.score = 0
    @c.send(:acidic_spacers, @seq)
    assert_equal(0, @seq.score)
  end
end
