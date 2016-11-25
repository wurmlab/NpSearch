require_relative 'test_helper'
require 'bio'

require 'npsearch/sequence'

# A class to test the Sequence Class
class TestSequences < Minitest::Test
  def setup
    seq = ">test_sequences\n" \
          "MFYFESFGRMWLVVCLLNSAFLTTVISGQADNTRAEVLSNAEIADEEAKELIDNLIKSKKDYS\n" \
          "SSDDDLYQMNEEDKRGLFPTGGMDPLGASYFTGKRGADSNEEETTDKRGFPNSRLDTLGSRYF\n" \
          "NGKRGFPNSGGLDTLGSRYFNGKRGFPSSGGMDTLGSGYFNGKRAFPSSGGMDTLGSRYFNGK\n" \
          "RAFPNSGGMDTLGSRYFNGKRGFPGSGGMDVLGSRYFNGKRGFPSSGGMDTLGSSYFNGKRGF\n" \
          "PSSGGMDTLGSGYFNGKRGFPNSGGMDTLGASYFTGKRGFPSSGGLDTLGSRYFNGKRGFPNS\n" \
          'GGMDTLGGRYFNGKRAIFDDFDQTDSLHGLKKGSSFLHGGLSSGGRVPGMKKRSVSSEENATE'
    sequence = Bio::FastaFormat.new(seq)
    sp = { name: 'test_sequences', cmax: '0.492', cmax_pos: '31', ymax: '0.612',
           ymax_pos: '31', smax: '0.950', smax_pos: '17', smean: '0.786',
           d: '0.706', sp: 'Y', dmaxcut: '0.300', networks: 'SignalP-noTM',
           orf: sequence.seq }
    @seq = NpSearch::Sequence.new(sequence, sp, 2)
  end

  def test_id
    assert_equal('test_sequences', @seq.id)
  end

  def test_sp
    sp = 'MFYFESFGRMWLVVCLLNSAFLTTVISGQA'
    assert_equal(sp, @seq.signalp)
  end

  def test_seq
    seq = 'DNTRAEVLSNAEIADEEAKELIDNLIKSKKDYSSSDDDLYQMNEEDKRGLFPTGGMDPLGASY' \
          'FTGKRGADSNEEETTDKRGFPNSRLDTLGSRYFNGKRGFPNSGGLDTLGSRYFNGKRGFPSSG' \
          'GMDTLGSGYFNGKRAFPSSGGMDTLGSRYFNGKRAFPNSGGMDTLGSRYFNGKRGFPGSGGMD' \
          'VLGSRYFNGKRGFPSSGGMDTLGSSYFNGKRGFPSSGGMDTLGSGYFNGKRGFPNSGGMDTLG' \
          'ASYFTGKRGFPSSGGLDTLGSRYFNGKRGFPNSGGMDTLGGRYFNGKRAIFDDFDQTDSLHGL' \
          'KKGSSFLHGGLSSGGRVPGMKKRSVSSEENATE'
    assert_equal(seq, @seq.seq)
  end

  def test_html_seq
    seq = '<span class=signalp>MFYFESFGRMWLVVCLLNSAFLTTVISGQA</span><span' \
          ' class=seq>DNTRAEVLSNAEIADEEAKELIDNLIKS<span class=np_clv>KK' \
          '</span>DYSSSDDDLYQMNEED<span class=np_clv>KR</span>GLFPTGGMDPLGASY' \
          'FT<span class=glycine>G</span><span class=np_clv>KR</span>GADSNEEE' \
          'TTD<span class=np_clv>KR</span>GFPNSRLDTLGS<span class=mono_np_clv' \
          '>R</span>YFN<span class=glycine>G</span><span class=np_clv>KR' \
          '</span>GFPNSGGLDTLGSRYFN<span class=glycine>G</span><span class' \
          '=np_clv>KR</span>GFPSSGGMDTLGSGYFN<span class=glycine>G</span>' \
          '<span class=np_clv>KR</span>AFPSSGGMDTLGSRYFN<span class=glycine>' \
          'G</span><span class=np_clv>KR</span>AFPNSGGMDTLGSRYFN<span class=' \
          'glycine>G</span><span class=np_clv>KR</span>GFPGSGGMDVLGSRYFN<span' \
          ' class=glycine>G</span><span class=np_clv>KR</span>GFPSSGGMDTLGSSY' \
          'FN<span class=glycine>G</span><span class=np_clv>KR</span>GFPSSGGM' \
          'DTLGSGYFN<span class=glycine>G</span><span class=np_clv>KR</span>' \
          'GFPNSGGMDTLGASYFT<span class=glycine>G</span><span class=np_clv>KR' \
          '</span>GFPSSGGLDTLGSRYFN<span class=glycine>G</span><span class=' \
          'np_clv>KR</span>GFPNSGGMDTLGGRYFN<span class=glycine>G</span>' \
          '<span class=np_clv>KR</span>AIFDDFDQTDSLHGL<span class=np_clv>KK'\
          '</span>GSSFLHGGLSSGGRVPGM<span class=np_clv>KK</span>RSVSSEENATE'\
          '</span>'
    assert_equal(seq, @seq.html_seq)
  end

  def test_translated_frame
    frame = 2
    assert_equal(frame, @seq.translated_frame)
  end

  def test_default_score
    score = 0
    assert_equal(score, @seq.score)
  end

  def test_default_potential_cleaved_nps
    potential_cleaved_nps = nil
    assert_equal(potential_cleaved_nps, @seq.potential_cleaved_nps)
  end
end
