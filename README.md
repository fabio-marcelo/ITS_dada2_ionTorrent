# ITS_dada2_ionTorrent

Este repositório demostra como analisar dados de metagenômica para ITS (internal transcribed spacer) de fungos sequenciados em plataforma Ion S.

# Requisitos
* OS Linux
* Instalaçao do [miniconda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) 
* Instalação do [qiime2](https://docs.qiime2.org/2022.11/install/native/#install-qiime-2-within-a-conda-environment)

# Importar sequências para dentro do qiime2
## Criar arquivo para importação (manifest file)
*


```bash
qiime tools import --type 'SampleData[SequencesWithQuality]' \       #demultiplexed single-end sequence data
```
