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

Option 1

  1. Download the source files. 
  2. Open the Terminal and change the directory to the source folder
  3. Then type

  $ bundle install 

Option 2 (When finally released)
  
  1. Simply open the Terminal and type this

	$ gem install np_search


## Usage

    Usage: $ np_search [Options] -m [Motif] -t [Input Type] -i [Input File] -o [Output Folder Name]

Where:

  Mandatory Options:

    -m, --motif [Query Motif]        The query motif to be searched for.
                                     The period "." can be used to denote any character. Multiple
                                     motifs query can be used by using a pipeline character ("|")
                                     between each query and putting the motif query in speech marks
                                     e.g. "KR|RR|R..R"
                                     Advanced Users: Regular expressions are supported in the motif.
    -t, --input_type [type]          The type of data in the input query file. The only two options
                                     available are "genetic" and "protein".
    -i, --input [file]               The input file. This can be a relative or a full path.
    -o, --output [folder name]       The path to the output folder. This will be created if the folder does not already exist.

  Optional Options:

    -c, --cut_off N                  Changes the default minimum Open Reading Frame from 10 amino acid residues to N amino acid residues.
    -s, --signalp_file [file]        Supply the output file of the Signal Peptide script (version 4.x) to the script.
                                      Otherwise the script will try to run the external Signal Peptide script when running.
    -a, --output_all                 Outputs all possible files.
    -e, --extract_orf                Only extracts the Open Reading Frames.
    -v, --verbose                    Provides more information on each step taken in this program.
    -h, --help                       Display this screen
        --version                    Shows version

## Examples

Help can be accessed easily, directly from the command line:

    $ np_search -h

### Example 1 
    $ np_search -v -a -c 25 -m neuro_clv -t genetic -i genetic_data.fa -o starfish
  
  The Example Explained:

  -v                  = Optional - Runs the verbose options
  -a                  = Optional - Runs the Output_all Option
  -c 25               = Optional -
  -m neuro_clv        = Mandatory - 
  -t genetic          = Mandatory - Describes the type of input data 
                        (can be either "genetic" or "protein")
  -i genetic_data.fa  = Mandatory
  -o starfish         = Mandatory



Further information on running the script on test material is provided within the test suite download.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
