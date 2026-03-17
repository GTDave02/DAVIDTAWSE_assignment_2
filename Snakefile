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
        f"{RAW_DIR}/reference.dict",
        f"{ALIGNED_DIR}/aligned.sam",
        f"{ALIGNED_DIR}/aligned.sorted.bam",
        f"{ALIGNED_DIR}/dedup.bam",
        f"{ALIGNED_DIR}/dedup.bam.bai",
        f"{VARIANT_DIR}/raw_variants.vcf",
        f"{VARIANT_DIR}/filtered_variants.vcf",
        f"{SNPEFF_DATA_DIR}/genes.gbk",
    
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

rule fasta_dictionary:
    input:
        f"{RAW_DIR}/reference.fasta"
    output:
        f"{RAW_DIR}/reference.dict"
    shell:
        """
        gatk CreateSequenceDictionary -R {RAW_DIR}/reference.fasta -O {RAW_DIR}/reference.dict
        """

rule align_reads:
    input:
        f"{RAW_DIR}/reference.fasta",
        f"{RAW_DIR}/{SRA}.fastq",
        f"{RAW_DIR}/reference.fasta.amb",
        f"{RAW_DIR}/reference.fasta.ann",
        f"{RAW_DIR}/reference.fasta.bwt",
        f"{RAW_DIR}/reference.fasta.pac",
        f"{RAW_DIR}/reference.fasta.sa"
    output:
        f"{ALIGNED_DIR}/aligned.sam"
    shell:
        """
        bwa mem -R '@RG\\tID:1\\tLB:lib1\\tPL:illumina\\tPU:unit1\\tSM:sample1' {RAW_DIR}/reference.fasta {RAW_DIR}/{SRA}.fastq > {ALIGNED_DIR}/aligned.sam
        """

rule convert_sam:
    input:
        f"{ALIGNED_DIR}/aligned.sam"
    output:
        f"{ALIGNED_DIR}/aligned.sorted.bam"
    shell:
        """
        samtools view -b {ALIGNED_DIR}/aligned.sam | samtools sort -o {ALIGNED_DIR}/aligned.sorted.bam
        """

rule mark_duplicates:
    input:
        f"{ALIGNED_DIR}/aligned.sorted.bam"
    output:
        f"{ALIGNED_DIR}/dedup.bam",
        f"{ALIGNED_DIR}/dup_metrics.txt"
    shell:
        """
        gatk MarkDuplicates -I {ALIGNED_DIR}/aligned.sorted.bam -O {ALIGNED_DIR}/dedup.bam -M {ALIGNED_DIR}/dup_metrics.txt
        """

rule index_dedup:
    input:
        f"{ALIGNED_DIR}/dedup.bam"
    output:
        f"{ALIGNED_DIR}/dedup.bam.bai"
    shell:
        """
        samtools index {ALIGNED_DIR}/dedup.bam
        """

rule call_variants:
    input:
        f"{RAW_DIR}/reference.fasta",
        f"{ALIGNED_DIR}/dedup.bam"
    output:
        f"{VARIANT_DIR}/raw_variants.vcf",
        f"{VARIANT_DIR}/raw_variants.vcf.idx"
    shell:
        """
        gatk HaplotypeCaller -R {RAW_DIR}/reference.fasta -I {ALIGNED_DIR}/dedup.bam -O {VARIANT_DIR}/raw_variants.vcf
        """

rule filter_variants:
    input:
        f"{RAW_DIR}/reference.fasta",
        f"{VARIANT_DIR}/raw_variants.vcf"
    output:
        f"{VARIANT_DIR}/filtered_variants.vcf"
    shell:
        """
        gatk VariantFiltration -R {RAW_DIR}/reference.fasta -V {VARIANT_DIR}/raw_variants.vcf -O {VARIANT_DIR}/filtered_variants.vcf --filter-expression "QD < 2.0 || FS > 60.0" --filter-name FILTER
        """

rule download_genbank:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created"
    output:
        f"{SNPEFF_DATA_DIR}/genes.gbk"
    shell:
        """
        efetch -db nucleotide -id {REF_ID} -format genbank > {SNPEFF_DATA_DIR}/genes.gbk
        """

