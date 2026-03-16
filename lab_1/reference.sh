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
BUCKET="sohail-binf55062"
S3_PREFIX="ebola"

rule all:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created",
        f"{RAW_DIR}/reference.fasta",
        f"{RAW_DIR}/{SRA}.fastq",
        f"{SNAKEMAKE_DIR}/s3_upload",

rule create_dirs:
    output:
        f"{SNAKEMAKE_DIR}/dirs_created"
    
    shell:
        """
        mkdir -p {RAW_DIR} {ALIGNED_DIR} {VARIANT_DIR} {ANNOTATED_DIR} {QC_DIR} {SNPEFF_DATA_DIR}
        touch {SNAKEMAKE_DIR}/dirs_created
        """

rule download_fasta:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created"
        
    output:
        f"{RAW_DIR}/reference.fasta"
    
    shell:
        """
        echo Downloading reference genome...
        efetch -db nucleotide -id {REF_ID} -format fasta > {RAW_DIR}/reference.fasta
        echo Downloaded reference genome!
        """

rule download_fastq:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created"
        
    output:
        f"{RAW_DIR}/{SRA}.fastq"
    
    shell:
        """
        echo Downloading sequencing data...
        prefetch {SRA} -O {RAW_DIR}
        fastq-dump -X 10000 {RAW_DIR}/{SRA}/{SRA}.sra -O {RAW_DIR}
        echo Downloaded sequencing data!
        """

rule s3_upload:
    input:
        f"{SNAKEMAKE_DIR}/dirs_created",
        f"{RAW_DIR}/reference.fasta",
        f"{RAW_DIR}/{SRA}.fastq",

    output:
        f"{SNAKEMAKE_DIR}/s3_upload"
    
    run:
        import os
        import boto3
        s3 = boto3.client("s3")
 
        for root, dirs, files in os.walk(RESULTS_FOLDER):
            for file in files:
                local_file = os.path.join(root, file)
                relative_path = os.path.relpath(local_file, RESULTS_FOLDER)
                s3_key = os.path.join(S3_PREFIX, relative_path).replace("\\", "/")
 
                print(f"Uploading {local_file} to s3://{BUCKET}/{s3_key}")
                s3.upload_file(local_file, BUCKET, s3_key)

        with open(f"{SNAKEMAKE_DIR}/s3_upload", "w") as file:
            file.write("Upload Complete")

# rule s3_upload:
#     input:
#         f"{SNAKEMAKE_DIR}/dirs_created",
#         f"{RAW_DIR}/reference.fasta",
#         f"{RAW_DIR}/{SRA}.fastq",

#     output:
#         f"{SNAKEMAKE_DIR}/s3_upload"
    
#     shell:
#         """
#         aws s3 cp results s3://sohail-hanif-binf5506 --recursive
#         touch {SNAKEMAKE_DIR}/s3_upload
#         """