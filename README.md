# NeuroPeptideSearch (NpSearch)
[![Gem Version](https://badge.fury.io/rb/NpSearch.svg)](http://badge.fury.io/rb/NpSearch)
[![Build Status](https://travis-ci.org/IsmailM/NeuroPeptideSearch.svg?branch=master)](https://travis-ci.org/IsmailM/NeuroPeptideSearch)
[![Dependency Status](https://gemnasium.com/IsmailM/NeuroPeptideSearch.svg)](https://gemnasium.com/IsmailM/NeuroPeptideSearch)
[![Inline docs](http://inch-ci.org/github/IsmailM/NeuroPeptideSearch.png?branch=master)](http://inch-ci.org/github/IsmailM/NeuroPeptideSearch)

> A tool to identify noval Neuropeptides.

NpSearch (NeuroPeptideSearch) is a program that searches for potential neuropeptides precursors based on the motifs commonly found on a neuropeptide. Ideally, the input would be transcriptome or protein data since there are no introns to worry about and the signal peptide would be attached to the front of the precursor.

Currently, the program produces a long list of sequences that fulfil all the requirements to be a potential neuropeptide. This list needs to be further analysed to find potential neuropeptides. Future versions of the program will automatically analyse the output file and extract a list of highly likely neuropeptides.

NpSearch produces a number of files - the final output files is produced as a fasta file and as a colour coded html file that can be opened by any web browser or even in a word processor.

Note: For this program to work, you will need to obtain a copy of Signal P 4.1 from cbs at "http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp" and link this to the program. Alternatively you will require an output text file from the Signal P which you can input into the program.

** Currently only supported on Mac OS & Linux

If you use this program, please cite us:

Moghul I, Rowe M, Priyam A, ELphick M & Wurm Y <em>(in prep)</em> NpSearch: A Tool to Identify Novel Neuropeptides

## Installation

1. Simply open the terminal and type this
```
    $ gem install npsearch
```
## Usage

    * Usage: npsearch [Options] -i [Input File] -o [Output Folder Name]

    * Mandatory Options:

        -i, --input [file]               The input file (in fasta format). Can be a relative or a full
                                          path.
        -o, --output [folder name]       The path to the output folder. This will be created if the
                                          folder does not exist.

    * Optional Options:
        -m, --motif [Query Motif]        By default NpSearch only searches for dibasic cleavage site
                                          ("KR", "RR" or "KK"). This option allows one to change the
                                          set of cleavage sites to be searched.
                                          The period "." can be used to denote any character. Multiple
                                          motifs query can be used by using a pipeline character ("|")
                                          between each query and putting the motif query in speech marks
                                          e.g. "KR|RR|R..R"
                                          Advanced Users: Regular expressions are supported.
        -c, --cut_off N                  Changes the minimum Open Reading
                                          Frame from the default 10 amino acid residues to N amino acid
                                          residues.
        -s, --signalp_file [file]        Is used to supply the signal peptide results to the program.
                                          These signal peptide results must be created using the SignalP
                                          program (Version 4.x), downloadable from CBS. If this argument
                                          isn't suplied, then NpSearch will try to run a local version
                                          of the Signal P script.
        -e, --extract_orf                Only extracts the Open Reading Frames.
        -v, --verbose                    Provides more information on each step taken in this program.
        -h, --help                       Display this screen
            --version                    Shows version

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
