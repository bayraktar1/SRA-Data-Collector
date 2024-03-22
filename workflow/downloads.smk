configfile: "config/downloads.yaml"


import pandas as pd

sample_df = pd.read_csv(config['metadata_tsv'], sep='\t')
sample_df = sample_df.set_index('run_accession')
sample_df = sample_df.convert_dtypes()
paired = sample_df[(sample_df['platform'] == "ILLUMINA")]
single = sample_df[(sample_df['platform'] == "PACBIO_SMRT") | (sample_df['platform'] == "OXFORD_NANOPORE")]



rule all:
    input:
        expand('results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_{pair}.fastq.gz',
            zip,
            scientific_name=paired['scientific_name'].values,
            platform=paired['platform'].values,
            accession = list(paired.index),
            pair=[1,2]),

        expand('results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.fastq.gz',
            zip,
            scientific_name=single['scientific_name'].values,
            platform=single['platform'].values,
            accession = list(single.index))


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
        ntasks=1,
        cpus_per_task=6
    shell:
        """(
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        ) >{log} 2>&1"""
