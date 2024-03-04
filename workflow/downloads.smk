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
    shell:
        """
        mkdir -p "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}" && cd "$_" || exit
        prefetch "{wildcards.accession}"
        vdb-validate "{wildcards.accession}"
        """


rule fasterq_dump_pe:
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_1.fastq.gz",
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}_2.fastq.gz",
    shell:
        """
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        """

rule fasterq_dump_se:
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}/{accession}.fastq.gz",
    shell:
        """
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        """


rule get_fastq_pe_gz:
    output:
        # the wildcard name must be accession, pointing to an SRA number
        "data/pe/{accession}_1.fastq.gz",
        "data/pe/{accession}_2.fastq.gz",
    log:
        "logs/pe/{accession}.gz.log"
    params:
        extra="--skip-technical"
    threads: 6  # defaults to 6
    wrapper:
        "v3.4.0-25-g0e80586/bio/sra-tools/fasterq-dump"


rule get_fastq_se_gz:
    output:
        "data/se/{accession}.fastq.gz"
    log:
        "logs/se/{accession}.gz.log"
    params:
        extra="--skip-technical"
    threads: 6
    wrapper:
        "v3.4.0-25-g0e80586/bio/sra-tools/fasterq-dump"