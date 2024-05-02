# Pipeline for downloading samples from NCBI with Metadata

This snakemake pipeline takes NBCI taxon IDs, study accessions, and run accession and finds all associated samples. Next, metadata for the collected samples are fetched and cleaned. Finally, samples are downloaded in parallel. 

## Instructions
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake

snakemake -s workflow/metadata.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
snakemake -s workflow/downloads.smk --executor slurm -j 20 --default-resources slurm_account=dla_mm slurm_partition=cpu --keep-going --use-conda --conda-frontend mamba --latency-wait 60 --printshellcmds
```
`Metadata.smk` should NOT be run with `--keep-going`, all rules should always finish without errors. <br>
`Downloads.smk` should be run with `--keep-going`, because it is possible that the files belonging to a NCBI accession are no longer available which means that the rule for that accession will fail. Or a sample is invalid and will fail during fasterq-dump.

## Selecting species & accessions
You can specify NCBI taxon ids in `Data/taxons.txt`. Single or multiple taxons can be specified separated by a space. **If you specify a taxon id that belongs to a rank higher than a species, all species of that rank will be downloaded!**

Sample accession and study accession can be specified in `Data/accessions.txt`. All samples associated with a study will be collected and downloaded.

You can combine as long as you specify everything in their respective files.

## License

MIT License

Copyright (c) 2024 Doğukan Bayraktar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
