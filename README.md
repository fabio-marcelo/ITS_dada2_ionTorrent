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

```bash
qiime tools import --type 'SampleData[SequencesWithQuality]' \       #demultiplexed single-end sequence data
  --input-path path/manifest-file.tsv \                              #path/manifest-file
  --output-path import.qza \                                         #path to output
  --input-format SingleEndFastqManifestPhred33V2                     #variation of quality scores

```
