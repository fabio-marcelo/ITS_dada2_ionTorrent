#!/usr/bin/env bash

# Immediately stop on errors. keep track of the commands as they get executed. 
set -ue
# nao exibe os comandos
set +x


# This bash file runs analysis for fungal ITS sequencing data generated in Ion S platform
# through qiime2 using dada2

#####################################################################
############################### menu de ajuda #######################
#####################################################################
help()
{
  echo -en "This shell script runs taxonomy classification using qiime2\n"
  echo -en  "\n"
  echo -en "Sintaxe: bash its_dada2_iontorrent.sh [-h|i|p|r]\n" 
  echo -en "opções:\n"
  echo -en "-h    exibe esta ajuda\n"
  echo -en "-i    folder with fastq files\n"
  echo -en "-p    primer sequence\n"
  echo -en "-r    folder containing reference files\n"
  echo -en  "\n"
} 


#####################################################################
########## define parameters ########################################
#####################################################################
while getopts ":h:i:p:r:" flag
do
  case "${flag}" in
      h) help;;
      i) fastq_folder=$OPTARG;;
      p) primer_seq=$OPTARG;;
      r) ref_folder=$OPTARG;;
  esac
done



echo "fastq_folder: $fastq_folder";
echo "primer_seq: $primer_seq";
echo "ref_folder: $ref_folder";



#####################################################################
########## Main program #############################################
#####################################################################
# cria pasta necessarias
mkdir "$fastq_folder"/output
mkdir "$fastq_folder"/temp


# create manifest file
echo "sample-id" > "$fastq_folder"/temp/sample-id.txt
echo "absolute-filepath" > "$fastq_folder"/temp/filepath.txt

for i in $(ls "$fastq_folder"); do echo "$i" | awk -F _bp_ '{print $2}' | awk -F . '{print $1}' >> "$fastq_folder"/temp/sample-id.txt; done

find $(pwd)/"$fastq_folder"/*fastq >> "$fastq_folder"/temp/filepath.txt

paste "$fastq_folder"/temp/sample-id.txt "$fastq_folder"/temp/filepath.txt > "$fastq_folder"/temp/manifest-file.tsv


# import fastq files
qiime tools import --type 'SampleData[SequencesWithQuality]' \
--input-path "$fastq_folder"/temp/manifest-file.tsv \
--output-path "$fastq_folder"/temp/fastq_imported.qza \
--input-format SingleEndFastqManifestPhred33V2  


# visualize fastq files imported
qiime demux summarize \
--i-data "$fastq_folder"/temp/fastq_imported.qza \
--o-visualization "$fastq_folder"/output/inspec_import.qzv 


# trim primers
echo "start trimming"
qiime cutadapt trim-single \
--i-demultiplexed-sequences "$fastq_folder"/temp/fastq_imported.qza \
--p-front "$primer_seq" \
--p-error-rate 0 \
--o-trimmed-sequences "$fastq_folder"/temp/trimmed-seqs.qza \
--verbose


# denoising
echo "start denoising"
qiime dada2 denoise-single \
--i-demultiplexed-seqs "$fastq_folder"/temp/trimmed-seqs.qza \
--p-max-ee 2 \
--p-trunc-q 2 \
--p-trunc-len 0 \
--p-pooling-method 'pseudo' \
--p-chimera-method 'consensus' \
--o-representative-sequences "$fastq_folder"/temp/representative-seqs.qza \
--o-table "$fastq_folder"/temp/table-denoised.qza \
--o-denoising-stats "$fastq_folder"/temp/denoise-stats.qza


# visualize denoising
qiime metadata tabulate \
--m-input-file "$fastq_folder"/temp/denoise-stats.qza \
--o-visualization "$fastq_folder"/output/inspect_denoise-stats.qzv
echo "open qzv file in https://view.qiime2.org/"


# train classifier
echo "Import seq reference file"
qiime tools import \
--type FeatureData[Sequence] \
--input-path "$ref_folder"/sh_refs_qiime_ver9_99_s_29.11.2022_dev.fasta \
--output-path "$fastq_folder"/temp/reference_sequences.qza

echo "Import taxonomy reference file"
qiime tools import \
--type FeatureData[Taxonomy] \
--input-path "$ref_folder"/sh_taxonomy_qiime_ver9_99_s_29.11.2022_dev.txt \
--output-path "$fastq_folder"/temp/reference_taxonomy.qza \
--input-format HeaderlessTSVTaxonomyFormat

echo "Start trainning classifier"
time qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads "$fastq_folder"/temp/reference_sequences.qza \
--i-reference-taxonomy "$fastq_folder"/temp/reference_taxonomy.qza \
--o-classifier "$fastq_folder"/temp/trainned_classifier_qiime_release_s_29.11.2022.qza  


# taxonomy classification
echo "Starting Taxonomic identification"
qiime feature-classifier classify-sklearn \
--i-classifier "$fastq_folder"/temp/trainned_classifier_qiime_release_s_29.11.2022.qza \
--p-reads-per-batch 10000 \
--i-reads "$fastq_folder"/temp/representative-seqs.qza \
--o-classification "$fastq_folder"/output/taxonomyITS.qza

qiime metadata tabulate \
--m-input-file "$fastq_folder"/output/taxonomyITS.qza \
--o-visualization "$fastq_folder"/output/taxonomyITS.qzv

# make table
## export taxa
qiime tools export \
--input-path "$fastq_folder"/temp/table-denoised.qza \
--output-path feature-table

## export taxonomy
qiime tools export \
--input-path "$fastq_folder"/output/taxonomyITS.qza \
--output-path taxonomy

## replace header
cp taxonomy/taxonomy.tsv taxonomy/taxonomy_header.tsv
sed -i 's/Feature ID/#otu-id/g' taxonomy/taxonomy_header.tsv
sed -i 's/Taxon/taxonomy/g' taxonomy/taxonomy_header.tsv

## add metadata
biom add-metadata \
--input-fp feature-table/feature-table.biom \
--observation-metadata-fp taxonomy/taxonomy_header.tsv \
--output-fp "$fastq_folder"/output/biom-with-taxonomy.biom

## convert biom to text
biom convert \
--input-fp "$fastq_folder"/output/biom-with-taxonomy.biom \
--output-fp "$fastq_folder"/output/biom-with-taxonomy.tsv \
--to-tsv \
--observation-metadata-fp taxonomy/taxonomy_header.tsv \
--header-key taxonomy


## print columns except column one
cat data_toy/output/biom-with-taxonomy.tsv \
| cut --complement -f1 > data_toy/output/final_output.tsv
