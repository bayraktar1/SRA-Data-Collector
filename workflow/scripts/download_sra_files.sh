#!/usr/bin/env bash
# Download files from NCBI.

############################################################
# Help                                                     #
############################################################
show_help() {
    echo "Usage: $0 -f <Metadata file> -o <output directory>"
    echo "Options:"
    echo "  -h : Display this help message."
    echo "  -o : Output directory, must exist."
    echo "  -f : Metadata file."
    echo "  -i : Download illumina files (can be combined)."
    echo "  -n : Download nanopore files (can be combined)."
    echo "  -p : Download pacbio files. (can be combined)."
    echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

output="SRA_downloads"
input="results/metadata.csv"
illumina=false
nanopore=false
pacbio=false

############################################################
# Process the input                                        #
############################################################
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

while getopts "ho:f:inp" option; do
   case $option in
      h) # display Help
         show_help
         exit
         ;;
      o) # output
         output=$OPTARG
         ;;
      f) # Input metadata
         input=$OPTARG
         ;;
      i) # download illumina
         illumina=true
         ;;
      n) # download nanopore
         nanopore=true
         ;;
      p) # download pacbio
         pacbio=true
         ;;
     \?) # Invalid option
         echo "Error: Invalid option $1"
         exit
         ;;
   esac
done

############################################################
# Check required inputs                                    #
############################################################
if [ -z "$input" ] || [ -z "$output" ]; then
    echo "Error: Mandatory options (-o, -f) must be specified."
    exit 1
fi

input_path=$(realpath -e "${input}") || exit

############################################################
# Download files from SRA                                  #
############################################################

# if prefetch fails we can run the command again to continue where the download left of
# how do we know if the download failed?
# we can test the downloaded data with vdb-validate

download () {
    echo "${1}" "${2}" "${3}"
    mkdir -p "${2}"/"${3}" && cd "$_" || exit
    prefetch "${1}"
    vdb-validate "${1}"
    fasterq-dump "${1}" # Uses six threads by default
    gzip ./*.fastq
    mv "${1}"*.* "${1}"
    rm "${1}"/*.sra
    cd ../..
}

mkdir -p "${output}"
cd "${output}" || exit

tail -n +2 "${input_path}" | while read -r line; do

  id=$(echo "${line}" | awk -F '\t' '{print $1}')
  file_platform=$(echo "${line}" | awk -F '\t' '{print $2}')
  name=$(echo "${line}" | awk -F '\t' '{print $3}' | tr ' ' '_')

  if [ "${file_platform}" == "ILLUMINA" ] && [ "${illumina}"  ]; then
    download "${id}" "${name}" "illumina"
  elif [ "${file_platform}" == "OXFORD_NANOPORE" ] && [ "${nanopore}" ]; then
    download "${id}" "${name}" "nanopore"
  elif [ "${file_platform}" == "PACBIO_SMRT" ] && [ "${pacbio}" ]; then
    download "${id}" "${name}" "pacbio"
  fi

done

# This is a bad way to handle the output
# Need to think of something else
# Maybe extract the names from the samples somehow but how would you make that as the output in the rule?
# probably need to make a helper function in python and run that before the rule
# this then makes a list of directory names that should be output by the next rule aka this one
touch done.txt
cd ..

