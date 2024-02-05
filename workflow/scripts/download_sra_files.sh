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
    echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

output=""
input=""

############################################################
# Process the input                                        #
############################################################
while getopts "ho:f:" option; do
   case $option in
      h) # display Help
         show_help
         exit;;
      o) # output
         output=$OPTARG;;
      f) # Input metadata
         input=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option $1"
         exit;;
   esac
done


############################################################
# Check required inputs                                    #
############################################################
if [ -z "$input" ] ||[ -z "$output" ]; then
    echo "Error: Mandatory options (-o, -f) must be specified."
    exit 1
fi


#file='/home/bayraktar/PycharmProjects/reconstruct_plasmids_snakemake/results/test.csv'

#cd '/media/bayraktar/DATA/umcstage' || exit
cd "${output}" || exit

while read line; do {
  id=$(echo "${line}" | awk -F '\t' '{print $1}');
  name=$(echo "${line}" | awk -F '\t' '{print $49}');

	echo "${id}" "${name}"
  mkdir -p "${name}"
  cd "${name}" || exit
  prefetch "${id}"
  fasterq-dump "${id}"
  mv "${id}".* "${id}"
}
done < ${input}
#done < ${file}

