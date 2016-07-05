# NpSearch (NeuroPeptideSearch)
[![Build Status](https://travis-ci.org/wurmlab/NpSearch.svg?branch=master)](https://travis-ci.org/wurmlab/NpSearch)
[![Gem Version](https://badge.fury.io/rb/npsearch.svg)](http://badge.fury.io/rb/npsearch)
[![Dependency Status](https://gemnasium.com/wurmlab/NpSearch.svg)](https://gemnasium.com/wurmlab/NpSearch)



## Introduction
NpSearch is a tool that helps identify novel neuropeptides. As such it is not based on homology to existing neuropeptides - rather NpSearch is based on the common characteristics of neuropeptides and their precursors.

If you use this program, please cite us:

>Moghul I, Rowe M, Priyam A, ELphick M & Wurm Y <em>(in prep)</em> NpSearch: A Tool to Identify Novel Neuropeptides

NpSearch produces a fasta file and highly visual html file that are ordered by the likelihood of a sequence encoding a neuropeptide precursor.

NpSearch orders the results based on the following characteristics:

  - **Signal peptide**: All neuropeptide precursors must have a signal peptide. This is due to the fact that the final bioactive neuropeptide has to be secreted from the cell of synthesis in order to be functionally active.
  - **Cleavage sites**: Being derived from a precursor, the bioactive neuropeptide has to be cleaved out from the precursor. Prohormone convertase enzymes cleave these bioactive peptides at specific cleavage sites. Since certain cleavage motifs are more likely to be cleaved, NpSearch awards sequences with cleavage site motifs that are more likely to be cleaved with a higher score.
  - **C-terminal Glycine**: A significant number of bioactive neuropeptides have a C-terminal glycine, that is amidated during post-translation modification. NpSearch awards sequences that have a potential neuropeptide with a C-terminal glycine a higher score.
  - **Repeated peptides**: Some neuropeptide precursors contain numerous copies of the same neuropeptides (usually with slight sequence differences). NpSearch attempts to detect this by aligning all potential neuropeptides within a sequence. If a sequence is found to have multiple, similar predicted NPs, NpSearch awards it with a higher score.
  - **Acidic spacer regions**: Neuropeptide precursors that contain multiple neuropeptide copies tend to have highly acidic spacer regions that separate the NP copies. If detected by NpSearch, the sequence is awarded with a higher score.






## Installation

### Installation Requirements
* Ruby (>= 2.0.0)
* SignalP 4.1 (Available from [here](http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp))
* CD-HIT (Available from [here](http://weizhongli-lab.org/cd-hit/) - Suggested Installation via [Homebrew](http://brew.sh) or [Linuxbrew](http://linuxbrew.sh) - `brew install homebrew/science/cd-hit`)

## Installation
Simply run the following command in the terminal.

```bash
gem install npsearch
```

If that doesn't work, try `sudo gem install npsearch` instead.

##### Running From Source (Not Recommended)
It is also possible to run from source. However, this is not recommended.

```bash
# Clone the repository.
git clone https://github.com/wurmlab/npsearch.git

# Move into NpSearch source directory.
cd NpSearch

# Install bundler
gem install bundler

# Use bundler to install dependencies
bundle install

# Optional: run tests, build documentation and build the gem from source
bundle exec rake

# Run NpSearch.
bundle exec npsearch -h
# note that `bundle exec` executes NpSearch in the context of the bundle

# Alternativaly, install NpSearch as a gem
bundle exec rake install
npsearch -h
```




## Usage
Verify NpSearch installed by running the following command in the terminal:

```bash
npsearch
```

You should see the following output.

```bash
* Usage: npsearch [Options] -i [Input File]

* Mandatory Options:

    -i, --input [file]               Path to the input fasta file

* Optional Options:
    -s, --signalp_path               The full path to the signalp script. This can be downloaded from
                                      CBS. See https://www.github.com/wurmlab/NpSearch for more
                                      information
    -u, --usearch_path               The full path to the usearch binary. This script can be downloaded
                                      from .... See https://www.github.com/wurmlab/NpSearch for more
                                      information
    -n, --num_threads                The number of threads to use when analysing the input file
    -m, --orf_min_length N           The minimum length of a potential neuropeptide precursor.
                                      Default: 30
    -h, --help                       Display this screen
    -v, --version                    Shows version

```


### Example Usage Scenario
The following runs NpSearch on an input fasta dataset.

```bash
npsearch -i INPUT_FASTA_FILE -s /path/to/signalp -u /path/to/usearch -n NUM_THREADS
```

## Output
The output produced by NpSearch is presented in two manners. NpSearch produces a highly visual HTML file that can be open in any browsers (an example can seen [here]()) and a fasta file.

