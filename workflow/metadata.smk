configfile: "config/config.yaml"


rule all:
    input:
        'results/metadata.csv',
        'logs/processed_stats_per_platform.ipynb',



rule query_ncbi:
    """
    Download or use already present NCBI SRA database dump to 
    query for SRA samples
    """
    output:
        feather_file = "results/SRA.feather"
    params:
        database = config['database'],
        taxon = config['taxon_id']
    conda: "envs/Renv.yml"
    log: "logs/query_ncbi.log"
    threads: 1
    resources:
        runtime=60,
        partition="cpu",
        ntasks=1,
        cpus_per_task=1
    shell:
        r'''
        (workflow/scripts/retrieve_NCBI_metadata.R \
            --database {params.database} \
            --taxon_id {params.taxon} \
            --output {output.feather_file}) >{log} 2>&1
        '''


rule wrangle_metadata:
    """
    Wrangles metadata from NCBI so that all runs have a isolation source
    geolocation and collection date.
    """
    input:
        feather_file = rules.query_ncbi.output.feather_file
    output:
        metadata = 'results/metadata.csv',
        clean_tsv = 'results/clean_tsv.tsv'
    conda: "envs/metadata_notebook.yaml"
    threads: 1
    resources:
        runtime=60,
        partition="cpu",
        ntasks=1,
        cpus_per_task=1
    log: notebook="logs/processed_notebook.ipynb"
    notebook: "notebooks/wrangle_NCBI_metadata.py.ipynb"


rule platform_stats:
    """
    Runs a Jupyter notebook that creates some statistics about the species in the metadata per sequencing platform/
    """
    input:
        metadata = rules.wrangle_metadata.output.metadata
    output:
        # pdf = "results/stats.pdf",
        notebook = "logs/processed_stats_per_platform.ipynb"
    conda: "envs/stats_notebook.yml"
    threads: 1
    resources:
        runtime=60,
        partition="cpu",
        ntasks=1,
        cpu_per_task=1
    log: notebook="logs/processed_stats_per_platform.ipynb"
    notebook: "notebooks/stats_per_platform.py.ipynb"


# rule download_files:
#     """
#     Downloads FASTA / FASTQ files for ID's collected in wrangle_metadata with SRAtools
#     """
#     input:
#         metadata = rules.wrangle_metadata.output.clean_tsv
#     params:
#         download_dir = "results/SRA_downloads",
#         platforms = config['download_platforms']
#     output: "results/SRA_downloads/done.txt"
#     conda: "envs/SRAtools.yml"
#     threads: 6
#     resources:
#         runtime=1440,
#         partition="cpu",
#         ntasks=1,
#         cpus_per_task=6
#     log: "logs/download_files.log"
#     shell:
#         '''
#         (bash workflow/scripts/download_sra_files.sh \
#             -f {input.metadata} \
#             -o {params.download_dir} \
#             {params.platforms}
#         ) >{log} 2>&1'''

