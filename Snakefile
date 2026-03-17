SRA="SRR1972739"
REF_ID="AF086833.2"
RESULTS_FOLDER="results"
RAW_DIR=f"{RESULTS_FOLDER}/raw"
ALIGNED_DIR=f"{RESULTS_FOLDER}/aligned"
VARIANT_DIR=f"{RESULTS_FOLDER}/variants"
ANNOTATED_DIR=f"{RESULTS_FOLDER}/annotated"
QC_DIR=f"{RESULTS_FOLDER}/qc"
SNPEFF_DIR=f"{RESULTS_FOLDER}/snpEff"
SNPEFF_DATA_DIR=f"{SNPEFF_DIR}/data/reference_db"
SNAKEMAKE_DIR=f"{RESULTS_FOLDER}/snakemake"

rule all:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created",
        f"{RAW_DIR}/{SRA}.fastq",
        f"{QC_DIR}/{SRA}_fastqc.html",
        f"{RAW_DIR}/reference.fasta.fai",
        f"{RAW_DIR}/reference.fasta.amb",
    
rule create_dirs:
    output:
        f"{SNAKEMAKE_DIR}/dirs_created"

    shell:
        """
        mkdir -p {RESULTS_FOLDER} {SNAKEMAKE_DIR} {RAW_DIR} {ALIGNED_DIR} {VARIANT_DIR} {ANNOTATED_DIR} {QC_DIR} {SNPEFF_DATA_DIR}
        touch {SNAKEMAKE_DIR}/dirs_created
        """

rule download_fasta:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created"

    output:
        f"{RAW_DIR}/reference.fasta"

    shell:
        """
        efetch -db nucleotide -id {REF_ID} -format fasta > {RAW_DIR}/reference.fasta
        """

rule download_sequencing:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created"

    output:
        f"{RAW_DIR}/{SRA}.fastq"

    shell:
        """
        prefetch {SRA} -O {RAW_DIR}
        fastq-dump -X 10000 {RAW_DIR}/{SRA}/{SRA}.sra -O {RAW_DIR}
        """

rule run_fastqc:
    input:
        f"{RAW_DIR}/{SRA}.fastq"
    output:
        f"{QC_DIR}/{SRA}_fastqc.html",
        f"{QC_DIR}/{SRA}_fastqc.zip"
    shell:
        """
        fastqc -o {QC_DIR} {RAW_DIR}/{SRA}.fastq
        """

rule index_reference:
    input:
        f"{RAW_DIR}/reference.fasta"
    output:
        f"{RAW_DIR}/reference.fasta.fai"
    shell:
        """
        samtools faidx {RAW_DIR}/reference.fasta
        """

rule build_bwa:
    input:
        f"{RAW_DIR}/reference.fasta"
    output:
        f"{RAW_DIR}/reference.fasta.amb",
        f"{RAW_DIR}/reference.fasta.ann",
        f"{RAW_DIR}/reference.fasta.bwt",
        f"{RAW_DIR}/reference.fasta.pac",
        f"{RAW_DIR}/reference.fasta.sa"
    shell:
        """
        bwa index {RAW_DIR}/reference.fasta
        """