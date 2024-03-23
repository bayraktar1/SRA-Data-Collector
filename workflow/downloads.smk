configfile: "config/downloads.yaml"


import pandas as pd

sample_df = pd.read_csv(config['metadata_tsv'], sep='\t')
sample_df = sample_df.convert_dtypes()


def generate_file_paths(df):
    """
    Generate file paths based on the DataFrame.
    :param df: A pandas DataFrame with columns 'scientific_name', 'platform', and 'run_accession'
    :return: A list of file paths
    """
    file_paths = []
    for index, row in df.iterrows():
        if row['platform'] == "ILLUMINA":
            for pair in [1, 2]:
                file_path = f"results/SRA_downloads/{row['scientific_name']}/{row['platform']}/{row['run_accession']}/{row['run_accession']}_{pair}.fastq.gz"
                file_paths.append(file_path)
        else:
            file_path = f"results/SRA_downloads/{row['scientific_name']}/{row['platform']}/{row['run_accession']}/{row['run_accession']}.fastq.gz"
            file_paths.append(file_path)

    return file_paths



rule all:
    input:
        generate_file_paths(sample_df)


rule download:
    """
    Download .SRA files from NCBI with SRAtools and validate them
    """
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    conda: "envs/SRAtools.yml"
    log: "logs/download/{scientific_name}_{platform}_{accession}.log"
    threads: 1
    resources:
        runtime=60,
        partition="cpu",
        mem_mb=8000,
        max_mb=16000,
        ntasks=1,
        cpus_per_task=1
    shell:
        """(
        mkdir -p "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}" && cd "$_" || exit
        prefetch "{wildcards.accession}"
        vdb-validate "{wildcards.accession}"
        ) >{log} 2>&1"""


rule fasterq_dump_pe:
    """
    Convert .SRA files to paired fastq files and gzip them
    """
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_1.fastq.gz",
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_2.fastq.gz",
    conda: "envs/SRAtools.yml"
    log: "logs/fasterq_dump_pe/{scientific_name}_{platform}_{accession}.log"
    threads: 6
    resources:
        runtime=60,
        partition="cpu",
        mem_mb=4000,
        max_mb=8000,
        ntasks=1,
        cpus_per_task=6
    shell:
        """(
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        ) >{log} 2>&1"""

rule fasterq_dump_se:
    """
    Convert .SRA files to single end fastq files and gzip them
    """
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.fastq.gz",
    conda: "envs/SRAtools.yml"
    log: "logs/fasterq_dump_se/{scientific_name}_{platform}_{accession}.log"
    threads: 6
    resources:
        runtime=60,
        partition="cpu",
        mem_mb=4000,
        max_mb=8000,
        ntasks=1,
        cpus_per_task=6
    shell:
        """(
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        ) >{log} 2>&1"""
