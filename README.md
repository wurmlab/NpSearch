# NpSearch (NeuroPeptideSearch)
[![Build Status](https://travis-ci.org/wurmlab/NpSearch.svg?branch=master)](https://travis-ci.org/wurmlab/NpSearch)
[![Gem Version](https://badge.fury.io/rb/npsearch.svg)](http://badge.fury.io/rb/npsearch)
[![Dependency Status](https://gemnasium.com/wurmlab/NpSearch.svg)](https://gemnasium.com/wurmlab/NpSearch)

<strong>Please note this currently in beta. We are currently working on something new that is amazingly fast (i.e. a few seconds to run) and a lot better in every sense (it even has an easy-to-use clicky, pointy interface). So watch this place.</strong>

## Introduction
NpSearch is a tool that helps identify novel neuropeptides. As such it is not based on homology to existing neuropeptides - rather NpSearch is based on the common characteristics of neuropeptides and their precursors. In other words, it is a feature based tool.

The results produced includes the entire secretome ordered in the likelihood of the sequence encoding a neuropeptide. As such, it is expected that you only need to analyse the top half of the results. 

Importantly, NpSearch produces a highly visual html file where the signal peptide and potential cleavage sites are highlighted. Additionally, NpSearch produces a fasta file of the results (i.e. the ordered secretome) that can easily be used in your own pipelines.

If you use this program, please cite us:

> Moghul <em>et al.</em> <em>(in prep)</em> NpSearch: A Tool to Identify Novel Neuropeptides

NpSearch requires an input of a transcriptomic or predicted proteomic dataset, where each sequence is analysed and awarded a relative score of its likelihood of encoding a neuropeptide precursor. When provided with transcriptomic data, NpSearch translates each contig in all six frames and thereafter extracts all potential open reading frame (methionine to stop codon). Each predicted protein sequence is then analysed for the following neuropeptide-related characteristics:

**Signal peptide**: All neuropeptide precursors must have a signal peptide. This is due to the fact that the final bioactive neuropeptide has to be secreted from the cell of synthesis in order to be functionally active.

**Cleavage sites**: Being derived from a precursor, the bioactive neuropeptide has to be cleaved out from the precursor. Prohormone convertase enzymes cleave these bioactive peptides at specific cleavage sites. As certain cleavage motifs are more likely to be cleaved than other cleavage motifs, NpSearch awards sequences based on the type and number of cleavage sites present.

**C-terminal Glycine**: A significant number of bioactive neuropeptides have a C-terminal glycine that is amidated during post-translation modification. Thus such sequences are awarded with a higher score.

**Repeated peptides**: Numerous neuropeptide precursors are made up of multiple copies of the same neuropeptide. NpSearch attempts to clustering all potential cleaved neuropeptides, and then awarding sequences that produce larger clusters with a higher score.

**Acidic spacer regions**: Neuropeptide precursors that contain multiple neuropeptide copies tend to have highly acidic regions that separate these copies. If detected by NpSearch, the sequence is awarded with a higher score.


After analysing each sequence in the input dataset, NpSearch produces a visual html file and a fasta file, where sequences that are more likely to encode a neuropeptides precursor are placed at the top of the file. These results files can then be easily inspected and curated by researchers.







## Installation

### Installation Requirements
* Ruby (>= 2.0.0)
* SignalP 4.1.*z (Available from [here](http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp))
* CD-HIT (Available from [here](http://weizhongli-lab.org/cd-hit/) - Suggested Installation via [Homebrew](http://brew.sh) or [Linuxbrew](http://linuxbrew.sh) - `brew install homebrew/science/cd-hit`)
* EMBOSS (Available from [here](http://emboss.sourceforge.net) - Suggested Installation via [Homebrew](http://brew.sh) or [Linuxbrew](http://linuxbrew.sh) - `brew install homebrew/science/emboss`)


## Installation

<strong>While in beta, it is suggested that you run NpSearch from source (i.e. the non-recommended method below)</strong>

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

# Move into the NpSearch source directory.
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
* Description: A tool to identify novel neuropeptides.

* Usage: npsearch [Options] [Input File]

* Options
    -s path_to_signalp,              The full path to the SignalP script. This can be downloaded from
        --signalp_path                CBS. See https://www.github.com/wurmlab/NpSearch for more
                                      information
    -d, --temp_dir path_to_temp_dir  The full path to the temp dir. NpSearch will create the folder and
                                      then delete the folder once it has finished using them.
                                      Default: Hidden folder in the current working directory
    -n, --num_threads num_of_threads The number of threads to use when analysing the input file
    -l, --min_orf_length N           The minimum length of a potential neuropeptide precursor.
                                      Default: 30
    -m, --max_seq_length N           The maximum length of a potential neuropeptide precursor.
                                      Default: 600
    -h, --help                       Display this screen
    -v, --version                    Shows version
```


### Exemplar Usage Scenario
The following runs NpSearch on an input fasta dataset.

```bash
npsearch -s /path/to/signalp -n NUM_THREADS INPUT_FASTA_FILE
```

## Note

- With the current version of NpSearch, there is an issue with the number of threads used - it seems to use more threads than that specified in the command line argument 
- NpSearch is expected to produce a high system load (as shown in `top` / `htop`) - this is because NpSearch runs SignalP as a separate process for each sequence (to speed things up). As such the system load (which is the number of processes called per unit time) can be higher than expected. This is normally not a reason for concern - however, we will probably try and find the middle ground between the speed and the number of processes called (or maybe someone could rewrite SignalP in C with multicore support)...