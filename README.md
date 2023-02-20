# ITS_dada2_ionTorrent

Este repositório demostra como analisar dados de metagenômica para ITS (internal transcribed spacer) de fungos sequenciados em plataforma Ion S.

# Requisitos
* OS Linux
* Instalaçao do [miniconda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) 
* Instalação do [qiime2](https://docs.qiime2.org/2022.11/install/native/#install-qiime-2-within-a-conda-environment)

# Importar sequências para dentro do qiime2
## Criar arquivo para importação (manifest file)

```bash
echo "sample-id" > sample-id.tx
echo "absolute-filepath" > filepath.txt

for i in $(ls its_dir); do echo "$i" | awk -F _bp_ '{print $2}' | awk -F . '{print $1}' >> sample-id.txt; done
find $(pwd)/its_dir/*fastq >> filepath.txt

paste sample-id.txt filepath.txt > manifest-file.tsv
```

## Importar as sequências
O output será um arquivo .qza
```bash
qiime tools import --type 'SampleData[SequencesWithQuality]' \       #demultiplexed single-end sequence data
  --input-path path/manifest-file.tsv \                              #path/manifest-file
  --output-path import.qza \                                         #path to output
  --input-format SingleEndFastqManifestPhred33V2                     #variation of quality scores

```

## Visualizar o arquivo importado

```bash
qiime demux summarize \
  --i-data import.qza \                                             #arquivo gerado na importação
  --o-visualization inspec_import.qzv                               #output para visualizar em https://view.qiime2.org/
```

## Etapa de denoising (dada2)
* devido a variabilidade no comprimento das seqs para ITS, não usaremos o truncLen;
* --p-trim-left 15 conforme orientado em FAQ of dada2
* --p-trunc-q - Truncate reads at the first instance of quality score less than or equal to truncQ;
* --p-pooling-method 'pseudo' - samples are denoised independently once, ASVs detected in at least 2 samples are recorded, and samples are denoised independently a second time, but this time with prior knowledge of the recorded ASVs and thus higher sensitivity to those ASVs;
* --p-chimera-method 'consensus' - "pooled": All reads are pooled prior to chimera detection. "consensus": Chimeras are detected in samples individually, and sequences found chimeric in a sufficient fraction of samples are removed.

```bash
echo "Starting denoising"

qiime dada2 denoise-single \
  --i-demultiplexed-seqs import.qza \
  --p-trim-left 15 \
  --p-max-ee 2 \
  --p-trunc-q 2 \
  --p-trunc-len 0 \
  --p-pooling-method 'pseudo' \
  --p-chimera-method 'consensus' \
  --o-representative-sequences representative-seqs.qza \
  --o-table table.qza \
  --o-denoising-stats denoise-stats.qza
```

```bash
qiime demux summarize \
  --i-data denoise-stats.qza \                                             #arquivo gerado na importação
  --o-visualization denoise-stats.qzv                               #output para visualizar em https://view.qiime2.org/
```

## Identificação taxonômica

```bash
echo "Starting Taxonomic identification"

 qiime feature-classifier classify-sklearn \
 --i-classifier path_to/classifier_file.qza \
 --p-reads-per-batch 10000 \
 --i-reads representative-seqs.qza \
 --o-classification taxonomyITS.qza

 qiime metadata tabulate \
--m-input-file taxonomyITS.qza \
--o-visualization taxonomyITS.qzv
```
