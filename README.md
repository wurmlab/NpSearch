# NeuroPeptideSearch
Note: this is currently a beta version...

NPSearch (NeuroPeptideSearch) is a program that searches for potential neuropeptides precursors based on the motifs commonly found on a neuropeptide. Ideally, the input would be transcriptome or protein data since there are no introns to worry about. The program produces a list of sequences that all contain all the common motifs found in a neuropeptide, which would need to be further analysed. The default output is a fasta file and a word document in which the signal peptide and potential neuropeptide cleavage sites are colour-coded.

Note: For this program to work, you will need to obtain a copy of Signal P 4.1 from cbs at "http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp" and link this to the program.

##Outputs
The default output is just a fasta file and a colour-formatted word document. However, it is possible to get all the temporary file outputted (by using the "-a" option)

    protein.aa              The genome translated in all 6 frames (* represents stop codons)
    orf.fa                  All possible Open reading frames are extracted from protein.aa (i.e. any methionine residue to a stop codon.)
    orf_condensed.fa        Open reading frames that are longer than 10 residues.
    signalp_out.txt         A signal Peptide test done on each sequence in orf_condensed.fa
    signalp_seq.fa          Showing all sequences that have a signal peptide with "-" where the signal peptide cleavage site is AND have at least one neuropeptide cleavage site after the signal peptide cleavage site
    output.fa               Removal of duplicate entries i.e. those that have different identifiers but the same sequence. The Final output fasta file.
    output.docx             output.fa as a word document - Signal peptide in blue and the motif in red
    
## Installation

Simply open the Terminal and type this
	
	$ gem install np_search


## Usage

    Usage: np_search.rb [options] InputFile InputType Motif

Where:

    InputFile: The Input query file
    InputType: The type of data in the input query file. Only "dna", "rna"and "protein" are supported.
    Motif: The query motif to be searched for. The period "." stands for any character.
    Advanced Users: Regex is supported in the Motif query

Options

    -v, --verbose                    Output more information; explaining each step in the pipeline.
    -a, --output_all                 Outputs all possible files
    -h, --help                       Display this screen

## Test_Example

An example set of data can be downloaded from ... The script can be run on the examplar data by typing this into the terminal.

    $ np_search -v -a genetic.fa genetic neuro_clv

Further information on running the script on test material is provided within the test suite download.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
