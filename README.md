# Pipeline for downloading samples from NCBI with Metadata

This snakemake pipeline takes NBCI taxon IDs, study accessions, and run accession and finds all associated samples. Next, metadata for the collected samples are fetched and cleaned. Finally, samples are downloaded in parallel. 

## Instructions
In order to run the pipeline you must install Snakemake with Jupyter notebook support in a conda/mamba environment. Please refer to the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for install instructions. 
Snakemake pipelines can be run locally on you computer or on High Performance clusters with job schedulers. 
### Run locally without a config
```bash
git clone https://github.com/bayraktar1/reconstruct_plasmids_snakemake.git
cd reconstruct_plasmids_snakemake

# You can optionally pass "--conda-frontend mamba" if you have mamba installed to speed up environment creation
snakemake -s workflow/metadata.smk --cores <number of cores> --use-conda --latency-wait 60 --printshellcmds
snakemake -s workflow/downloads.smk --cores <number of cores> --keep-going --use-conda --latency-wait 60 --printshellcmds
```
`Metadata.smk` should NOT be run with `--keep-going`, all rules should always finish without errors. <br>

`Downloads.smk` should be run with `--keep-going`, because it is possible that the files belonging to a NCBI accession are no longer available which means that the rule for that accession will fail. Or a sample is invalid and will fail during fasterq-dump.

It is recommended to pass 10-20 cores to the `downloads.smk` to significantly speed up downloading samples.

## Selecting species & accessions
You can specify NCBI taxon ids in `Data/taxons.txt`. Single or multiple taxons can be specified separated by a space. **If you specify a taxon id that belongs to a rank higher than a species, all species of that rank will be downloaded!**

Sample accession and study accession can be specified in `Data/accessions.txt`. All samples associated with a study will be collected and downloaded.

You can combine as long as you specify everything in their respective files.

**Samples that fall under "strains" in the NCBi database are currently not found when searching through a higher taxon rank.**


# Roadmap
- [ ] Ensure that samples classified as strains are found by SRA-Data-Collector
- [ ] Move away from Snakemake and make an independent package
- [ ] Move away from SRAdb
- [ ] Expand processing of Country names beyond INSDC list with fuzzy searching
- [ ] Improve processing of sample sources names by creating categories/groups


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
