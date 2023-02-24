# ITS_dada2_ionTorrent

Este repositório demonstra como analisar dados de metagenômica para ITS (internal transcribed spacer) de fungos sequenciados em plataforma Ion S.

# Requisitos
* OS Ubuntu
* Arquivos fastq gerados em plataform Ion S
* Instalaçao do [miniconda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) e consequente instalação do 
[qiime2](https://docs.qiime2.org/2022.11/install/native/#install-qiime-2-within-a-conda-environment) em ambiente conda **OU**
* Instalação de docker e inicialização de container pela imagem docker pull qiime2/simple-remote-directory-resource
* Banco de dados para classificação taxonômica de ITS

# Banco de dados
## Obtenção do banco de dados
### Banco de dados Unite
O banco de dados do Unite está disponível [no site](https://unite.ut.ee/repository.php#qiime). O banco formatado para análise na ferramenta qiime2 
é disponibilizado em 3 níveis de clusterização por similaridade: a) 97%; b) 99% e c) dinâmico com níveis escolhidos manualmente por especialistas
em linhagens particulares de fungos, limitados ao nível de 3% de dissimilaridade. 

Fazer o download do banco escolhido.
```bash
# ultima versao
wget -c https://files.plutof.ut.ee/public/orig/98/AE/671C4D441E50DCD30691B84EED22065D77BAD3D18AF1905675633979BF323754.tgz \
    -O sh_qiime_release_s_29.11.2022.tgz
```

 Proceder com a descompactação
```bash
tar -xvf nome_do_arquivo.tgz
```

Remover espaços em branco e caracteres minúsculos no arquivo fasta da referência.
```bash
awk '/^>/ {print($0)}; /^[^>]/ {print(toupper($0))}' nome_do_arquivo.fasta | tr -d ' ' > nome_do_arquivo_uppercase.fasta
```

### Banco de dados Bold

### Banco de dados NCBI



# Importar sequências para dentro do qiime2
## Criar arquivo para importação das reads (manifest file)

```bash
echo "sample-id" > sample-id.tx
echo "absolute-filepath" > filepath.txt

for i in $(ls its_dir); do echo "$i" | awk -F _bp_ '{print $2}' | awk -F . '{print $1}' >> sample-id.txt; done
find $(pwd)/its_dir/*fastq >> filepath.txt

paste sample-id.txt filepath.txt > manifest-file.tsv
```

## Importar as sequências geradas no sequenciamento
O output será um arquivo .qza
```bash
qiime tools import --type 'SampleData[SequencesWithQuality]' \       #demultiplexed single-end sequence data
  --input-path path/manifest-file.tsv \                              #path/manifest-file
  --output-path import.qza \                                         #path to output
  --input-format SingleEndFastqManifestPhred33V2                     #variation of quality scores

```

### Visualizar o arquivo importado

```bash
qiime demux summarize \
  --i-data import.qza \                                             #arquivo gerado na importação
  --o-visualization inspec_import.qzv                               #output para visualizar em https://view.qiime2.org/
```

## Etapa de denoising (dada2)
### Executar denoising
* devido a variabilidade no comprimento das seqs para ITS, não usaremos o --p-trunc-len [tutorial](https://benjjneb.github.io/dada2/ITS_workflow.html);
* --p-trim-left 15 conforme orientado em FAQ of dada2
* --p-trunc-q - Truncate reads at the first instance of quality score less than or equal to truncQ;
* --p-pooling-method 'pseudo' - samples are denoised independently once, ASVs detected in at least 2 samples are recorded, and samples are denoised independently a second time, but this time with prior knowledge of the recorded ASVs and thus higher sensitivity to those ASVs;
* --p-chimera-method 'consensus' - "pooled": All reads are pooled prior to chimera detection. "consensus": Chimeras are detected in samples individually, and sequences found chimeric in a sufficient fraction of samples are removed.

```bash
echo "Starting denoising"

qiime dada2 denoise-single \                                  #This method denoises single-end sequences, dereplicates them, and filters chimeras
  --i-demultiplexed-seqs import.qza \
  --p-trim-left 15 \
  --p-max-ee 2 \
  --p-trunc-q 2 \
  --p-trunc-len 0 \
  --p-pooling-method 'pseudo' \
  --p-chimera-method 'consensus' \
  --o-representative-sequences representative-seqs.qza \                    #output
  --o-table table.qza \                                                     #output
  --o-denoising-stats denoise-stats.qza                                     #output
```

#### Visualizar resultado do denoising
```bash
qiime metadata tabulate \
--m-input-file denoise-stats.qza \
--o-visualization inspect_denoise-stats.qzv                               #output para visualizar em https://view.qiime2.org/
```

## Identificação taxonômica
### Treinamento do classificador

```bash
# importar o arquivo de sequencias
echo "Import seq file"

qiime tools import \
 --type FeatureData[Sequence] \
 --input-path path/to/fasta_file/with?refseqs \
 --output-path path/outputfilename.qza
```

```bash
# importar arquivo com taxonomia
echo "Import tax file"

qiime tools import \
 --type FeatureData[Taxonomy] \
 --input-path path/to/txtfile/with/taxonomy \
 --output-path unite-ver7-99-tax-01.12.2017.qza \
 --input-format HeaderlessTSVTaxonomyFormat
```

Não é aconselhado extrair/trimar sequências do db referência antes de treinar o classificador [referência](https://github.com/qiime2/docs/blob/master/source/tutorials/feature-classifier.rst).

```bash
# treinar o classificador
qiime feature-classifier fit-classifier-naive-bayes \       #metodo
     --i-reference-reads ref-seqs.qza \                     #sequencias ref
     --i-reference-taxonomy ref-taxonomy.qza \              #taxnomia do db
     --o-classifier classifier.qza                          #output

```

```bash
# classify-sklearn - usa banco treinado a priori
# para treinar db usar fit-classifier-naive-bayes ou fit-classifier-sklearn


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
