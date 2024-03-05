configfile: "config/config.yaml"


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
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    conda: "envs/SRAtools.yml"
    log: "logs/download_{scientific_name}_{platform}_{accession}.log"
    threads: 1
    shell:
        """(
        mkdir -p "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}" && cd "$_" || exit
        prefetch "{wildcards.accession}"
        vdb-validate "{wildcards.accession}"
        ) >{log} 2>&1"""


rule fasterq_dump_pe:
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_1.fastq.gz",
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_2.fastq.gz",
    conda: "envs/SRAtools.yml"
    log: "logs/fasterq_dump_pe_{scientific_name}_{platform}_{accession}.log"
    threads: 6
    shell:
        """(
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        ) >{log} 2>&1"""

rule fasterq_dump_se:
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.fastq.gz",
    conda: "envs/SRAtools.yml"
    log: "logs/fasterq_dump_se_{scientific_name}_{platform}_{accession}.log"
    threads: 6
    shell:
        """(
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        ) >{log} 2>&1"""
