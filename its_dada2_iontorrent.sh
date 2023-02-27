#!/bin/bash

# Immediately stop on errors. keep track of the commands as they get executed. 
set -uex

# This bash file runs analysis for fungal ITS sequencing data generated in Ion S platform
# through qiime2 using dada2

#define fastq files folder
folder=data_toy
primer=
reference_folder=

# create manifest file
echo "sample-id" > sample-id.txt
echo "absolute-filepath" > filepath.txt

for i in $(ls "$folder"); do echo "$i" | awk -F _bp_ '{print $2}' | awk -F . '{print $1}' >> sample-id.txt; done

find $(pwd)/"$folder"/*fastq >> filepath.txt

paste sample-id.txt filepath.txt > manifest-file.tsv

# import fastq files
qiime tools import --type 'SampleData[SequencesWithQuality]' \       
  --input-path manifest-file.tsv \                              
  --output-path fastq_imported.qza \                                         
  --input-format SingleEndFastqManifestPhred33V2  

# visualize fastq files imported
qiime demux summarize \
--i-data import.qza \
--o-visualization inspec_import.qzv 

# trim primers
echo "start trimming"
qiime cutadapt trim-single \
--i-demultiplexed-sequences fastq_imported.qza \
--p-front GGAAGTAAAAGTCGTAACAAGG \
--p-error-rate 0 \
--o-trimmed-sequences trimmed-seqs.qza \
--verbose

# denoising
echo "start denoising"
qiime dada2 denoise-single \
--i-demultiplexed-seqs trimmed-seqs.qza \
--p-max-ee 2 \
--p-trunc-q 2 \
--p-trunc-len 0 \
--p-pooling-method 'pseudo' \
--p-chimera-method 'consensus' \
--o-representative-sequences representative-seqs.qza \
--o-table table-denoised.qza \
--o-denoising-stats denoise-stats.qza

# visualize denoising
qiime metadata tabulate \
--m-input-file denoise-stats.qza \
--o-visualization inspect_denoise-stats.qzv
echo "open qzv file in https://view.qiime2.org/"

# train classifier
echo "Import seq reference file"

qiime tools import \
--type FeatureData[Sequence] \
--input-path reference_folder/sh_refs_qiime_ver9_99_s_29.11.2022_dev.fasta \
--output-path reference_sequences.qza

echo "Import taxonomy reference file"
qiime tools import \
--type FeatureData[Taxonomy] \
--input-path reference_folder/sh_taxonomy_qiime_ver9_99_s_29.11.2022_dev.txt \
--output-path reference_taxonomy.qza \
--input-format HeaderlessTSVTaxonomyFormat

echo "Start trainning classifier"
qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads reference_sequences.qza \
--i-reference-taxonomy reference_taxonomy.qza \
--o-classifier trainned_classifier_qiime_release_s_29.11.2022.qza  