# Pipeline for downloading samples from NCBI

## Main branch
De main branch download de samples niet in parallel
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake

# optioneel, maar de package die de NCBI SRAdb hoort te downloaden faalt vaak dus dit is consistenter
wget -p Data/ https://gbnci.cancer.gov/backup/SRAmetadb.sqlite.gz | gzip -d SRAmetadb.sqlite.gz

snakemake --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
```


## Separate flow branch
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake
gitcheckout separate_flows

# optioneel, maar de package die de NCBI SRAdb hoort te downloaden faalt vaak dus dit is consistenter
wget -p Data/ https://gbnci.cancer.gov/backup/SRAmetadb.sqlite.gz | gzip -d SRAmetadb.sqlite.gz

snakemake -s workflow/metadata.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
snakemake -s workflow/download.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
```

## Species selecteren
Je kan de species om te downloaden selecteren door het NCBI taxon id te specificeren in de `config/congig.yaml`.
Op moment staat het al klaar voor de Shigella dit zouden 330 samples moeten zijn. het kan zijn dat de database in de tussen tijd is geupdate en er nu meer samples zijn.

## Mogelijke problemen met paths
Ik weet niet zeker of je deze errors zal krijgen maar snakemake doet soms vervelend met paths dus misschien is het handig om dit gelijk te doen

1. `wrangle_NCBI_metadata.py.ipynb` kan het `wrangling_funcs.py` script niet vinden: maak een kopie en plaats het in de `notebooks` directory
2. `wrangling_funcs.py` kan de `Data/insdc_country_or_area.csv` file niet vinden: specificeer het absolute path naar de file op lijn 113 van het script 
3. Snakemake kan de database file die je hebt gedownload niet vinden: specificeer het absolute path van de `SRAmetadb.sqlite` file in `config/config.yaml`

## Flowchart
![Flowchart](NCBI_download.drawio.png)
