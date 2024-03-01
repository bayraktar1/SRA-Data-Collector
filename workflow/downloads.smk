configfile: "config/config.yaml"


import pandas as pd
from pathlib import Path

samples = []
for dir_path in Path('/hpc/dla_mm/dbayraktar/data/reconstruct_plasmids_snakemake/results/SRA_downloads').glob('*/illumina/*/'):
    fastqs = [fastq.resolve() for fastq in dir_path.glob('*.fastq.gz')]
    fastqs.sort()

    sample_info = {
        'Sample': dir_path.parts[-1],
        'Species': dir_path.parts[-3],
        'R1': fastqs[0],
        'R2': fastqs[1]
    }
    samples.append(sample_info)
sample_df = pd.DataFrame(data=samples)



rule all:
    input:
        expand('results/SRA_downloads/{scientific_name}/{platform}/{accession}',
            zip,
            scientific_name=sample_df['scientific_name'].values,
            platform=sample_df['platform'].values),
            accesssion = sample_df['run_accession'].values


rule download:
    input:
        "{scientific_name}",
        "{platform}",
        "{accession}"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}.sra"
    shell:
        """
        mkdir -p "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}" && cd "$_" || exit
        prefetch "{wildcards.accession}"
        vdb-validate "{wildcards.accession}"
        """


rule fasterq_dump:
    input:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}.sra"
    output:
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}_1.fastq.gz",
        "results/SRA_downloads/{scientific_name}/{platform}/{accession}_2.fastq.gz",
    shell:
        """
        cd "results/SRA_downloads/{wildcards.scientific_name}/{wildcards.platform}/{wildcards.accession}"
        fasterq-dump {wildcards.accession}
        gzip ./*.fastq
        """
