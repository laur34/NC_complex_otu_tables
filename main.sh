#!/bin/bash

# prompt user for input files
confirm(){
        read -r -p "${1:-Continue with selected inputs? [y/N]} " response
        case "$response" in
                [yY][eE][sS]|[yY])
        	        true
                	;;
        	*)
                	false
			exit 1
                	;;
        esac
}

if [[ $# -eq 0 ]]; then
	ARG1=$(ls otu_table_0.98.txt)
	ARG2=$(ls *.tsv | head -n1 | cut -f1)
	ARG3="neg"
	echo "$0: you provided no arguments to the script. Continue with defaults?"
	echo "--------------------------------------------------------------------"
	echo "Usage: $0 [OTU_TABLE] [TSV_TABLE] [NEG_CTRL_PATTERN]"
	echo "default otu table is otu_table_0.98.txt. Found $ARG1"
	echo "default tab-separated table is first tsv file found in directory. In your case it will be $ARG2"
	echo "Negative control pattern will be: $ARG3"
	echo
	confirm
elif [[ $# -eq 1 ]]; then
	ARG1=$1
	ARG2=$(ls *.tsv | head -n1 | cut -f1)
	ARG3="neg"
	echo "$0: you did not provide the tab-separated file or negative control pattern. Continue with defaults?"
	echo "--------------------------------------------------------------------"
	echo "Usage: $0 [OTU_TABLE] [TSV_TABLE] [NEG_CTRL_PATTERN]"
	echo "Input otu table you provided is: $ARG1"
	echo "Input tab-separated table will be: $ARG2"
	echo "Negative control pattern will be: $ARG3"
	echo
	confirm
elif [[ $# -eq 2 ]]; then
	ARG1=$1
	ARG2=$2
	ARG3="neg"
	echo "you did not provide a negative control string pattern. Continue with default ('neg')?"
	echo "--------------------------------------------------------------------"
	echo "Usage: $0 [OTU_TABLE] [TSV_TABLE] [NEG_CTRL_PATTERN]"
	echo
	confirm
elif [[ $# -eq 3 ]]; then
	ARG1=$1
	ARG2=$2
	ARG3=$3
	echo "Continue with provided inputs?"
	echo
	confirm
elif [[ $# -gt 3 ]]; then
	echo "$0: you provided too many arguments; exiting ..."
	echo
	exit 1
fi


otu_table=$ARG1
tsv_table=$ARG2
neg_pattern=$ARG3

#This is the main script. It will call the other scripts in this repo.
#Inputs are otu table and a tab-separated table of sample names and their respective data pool numbers.
#And you can specify negative control pattern to grep for (default is "neg").

##########################################################################

#Remove header from $otu_table, so that R can read it in correctly.
echo "Fixing otu table header for R."
sed -z 's/#OTU ID\t//' $otu_table > otutbl_nohashtag.csv

#Run R script which takes information from the "pool" column (second column) of TSV file, to separate the OTU table into subtables (1 subtable per pool).
echo "Running R script to create sub-otu-tables..."
Rscript create_subtables.R "$tsv_table"
echo
echo

#Put the hyphens back into the sample names (R can't use them) (Done in the R script)

#Apply v2_negative_controls_correction.sh on each of the above-created subtables. #### Did the script orig assume "#OTU ID" in otu tables? Because these don't have it.
#Other potential issue:  overwriting of intermediate files as v2 script is called repeatedly in loop
echo "Running negative control correction on the subtables..."

for subtab in subtable*.csv; do
    ./v2_negative_controls_correction.sh $subtab $neg_pattern
done

echo
echo

echo "Combining the filtered subtables..."
arr=(filtered_subtable*.csv)
#file="${arr[1]}"
file="${arr[0]}"

for f in "${arr[@]:1}"; do
    paste "$file" <(cut -d$'\t' -f2- "$f") > _file.tmp && mv _file.tmp file.tmp
    file=file.tmp
done

echo
echo
#Add first cell to header, and then even it out with column -t:
sed -z 's/^/ID/' file.tmp > filez.tmp
sed 's/\t\t/\t/g' filez.tmp > filtered_tbl_all.csv
#sed -i 's/\t\t/\t/g' filez.tmp


echo "Removing OTUs with zero reads overall."
##First calculate row sums and put on end of new file.
awk '{
	for (i=2; i<=NF; i++){
	sumrows+= $i
	}; print $0, sumrows; sumrows=0
}' filtered_tbl_all.csv > withrowsums.txt

echo
echo
##Then print rows of new file where sums are not zero.
awk '{if ( (NR!=1) && ($NF!= 0) ){print $0} }' withrowsums.txt > filteredall_wrs_nohead.csv
###Remove row sums
awk '{sub(/\s*\S+$/,"")}1' filteredall_wrs_nohead.csv > filteredall_nohead.csv
###Add back header
cat <(head -n1 filtered_tbl_all.csv) filteredall_nohead.csv > filtered_otu_table.csv

echo "Deleting intermediate files..."
rm f*.tmp *nohead.?sv *rowsums.txt filtered_tbl_all.csv max_neg_biol* biol_samples_header.tsv otutbl_nohashtag.csv
rm filtered_subtable*.csv subtable*.csv
echo
echo
echo "Done."
