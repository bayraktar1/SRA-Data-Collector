# Pipeline for downloading samples from NCBI

## Instructions
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake

snakemake -s workflow/metadata.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
snakemake -s workflow/downloads.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --keep-going --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
```
`Metadata.smk` should NOT be run with `--keep-going`, all rules should always finish without errors. <br>
`Downloads.smk` should be run with `--keep-going`, because it is possible that the files belonging to a NCBI accession are no longer available which means that the rule for that accession will fail.

## Selecting species
You can specify NCBI taxon ids in `config/metadata.yaml` under `taxon_id`. Single or multiple taxons can be specified separated by a space. **If you specify a taxon id that belongs to a rank higher than a species, all species of that rank will be downloaded!**
