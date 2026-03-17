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
        f"{RAW_DIR}",
        f"{ALIGNED_DIR}",
        f"{VARIANT_DIR}",
        f"{ANNOTATED_DIR}",
        f"{QC_DIR}",
        f"{SNPEFF_DATA_DIR}",
    
rule create_dirs:
    output:
        f"{SNAKEMAKE_DIR}/dirs_created"

    shell:
        """
        mkdir -p {SNAKEMAKE_DIR} {RAW_DIR} {ALIGNED_DIR} {VARIANT_DIR} {ANNOTATED_DIR} {QC_DIR} {SNPEFF_DATA_DIR}
        touch {SNAKEMAKE_DIR}/dirs_created
        """


