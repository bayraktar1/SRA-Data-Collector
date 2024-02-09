#!/bin/bash
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
    echo "  -p : platform: ILLUMINA, OXFORD_NANOPORE, PACBIO_SMRT"
    echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

output=""
input=""
platform=""

############################################################
# Process the input                                        #
############################################################
while getopts "ho:f:p:" option; do
   case $option in
      h) # display Help
         show_help
         exit;;
      o) # output
         output=$OPTARG;;
      f) # Input metadata
         input=$OPTARG;;
      p) # Input platform
         platform=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option $1"
         exit;;
   esac
done

############################################################
# Check required inputs                                    #
############################################################
if [ -z "$input" ] || [ -z "$output" ] || [ -z "$platform" ]; then
    echo "Error: Mandatory options (-o, -f, -p) must be specified."
    exit 1
fi

############################################################
# Download files from SRA                                  #
############################################################
mkidir "${output}"
cd "${output}" || exit

tail -n +2 "${input}" | while read -r line; do
  id=$(echo "${line}" | awk -F '\t' '{print $1}')
  file_platform=$(echo "${line}" | awk -F '\t' '{print $2}')
  name=$(echo "${line}" | awk -F '\t' '{print $3}' | tr ' ' '_')

  if [ "${file_platform}" == "${platform}" ]; then
    echo "${id}" "${name}"
    mkdir -p "${name}"
    cd "${name}" || exit
    prefetch "${id}"
    fasterq-dump "${id}" # Uses six threads by default
    gzip ./*.fastq
    mv "${id}"*.* "${id}"
    rm "${id}"/*.sra
    cd ..
  fi
done

touch done.txt
cd ..

