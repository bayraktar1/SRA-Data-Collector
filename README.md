# Pipeline for downloading samples from NCBI

## Installation
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake
```

## Run directly with Snakemake
```
# replace slurm specific settings with your scheduler
snakemake -s workflow/metadata.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
snakemake -s workflow/downloads.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --keep-going --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
```

## Run with wrapper script
```
# Create and specify a profile for your scheduler
python run_pipelines.py -t <taxon ids> -d profiles/downloads_slurm -m profiles/metadata_slurm
```
`Metadata.smk` should NOT be run with `--keep-going`, all rules should always finish without errors. <br>
`Downloads.smk` should be run with `--keep-going`, because it is possible that the files belonging to a NCBI accession are no longer available for download which means that the rule for that accession will fail.
