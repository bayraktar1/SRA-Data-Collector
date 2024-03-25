
import argparse
import subprocess
import sys

parser = argparse.ArgumentParser(description='')
parser.add_argument('-t', '--taxon', required=True, type=str, help='List of NCBI taxon IDs')
parser.add_argument('-d', '--downloads_profile', required=True, help='Pass a directory with profile settings for downloads.smk')
parser.add_argument('-m', '--metadata_profile', required=True, help='Pass a directory with profile settings for metadata.smk')
args = parser.parse_args()


def runsnake(command):
    run = subprocess.run(command, shell=True, text=True, executable='/bin/bash')
    if run.returncode == 1:
        print(
            "It looks like Snakemake encountered an error. Please refer to the Snakemake output to see what went wrong")
        sys.exit(1)
    else:
        return 0


command_create_envs_metadata = f"snakemake -s snakefiles/metadata.smk --use-conda --conda-frontend mamba --conda-create-envs-only"
command_create_envs_download = f"snakemake -s snakefiles/download.smk --use-conda --conda-frontend mamba --conda-create-envs-only"

command_run_metadata = f"snakemake --profile {args.downloads_profile} --config taxon_id={args.taxon}"
command_run_download = f"snakemake --profile {args.metdata_profile} --config metadata_tsv=results/clean_tsv.tsv"


runsnake(command_create_envs_metadata)
runsnake(command_run_metadata)

runsnake(command_create_envs_download)
runsnake(command_run_download)
