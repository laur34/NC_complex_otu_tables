#!/bin/bash

# a script for filtering out reads from OTU tables ...
# ...based on the number of reads in negative control samples

# script takes as input a pattern to recognize ...
# ...which samples are biological, and which are negative controls

# by VB@AIM, 04.10.2021

subtab="$1"
neg_pattern="$2"

# find maximum of columns with neg_pattern in header
tail -n +2 $subtab | \
	cut -f $(head -1 $subtab | \
	tr "\t" "\n" | \
	grep -n $neg_pattern | \
	cut -d":" -f1 | \
	tr "\n" "," | \
	perl -pe 's/,$/\n/g') | \
	awk -F $'\t' '{OFS=FS; m=$1; for(i=1;i<=NF;i++) if($i>m) m=$i; print m}' \
	> neg_ctrls_max_nohead.tsv

# find columns without neg_pattern in header ...
# ...and join with the maximum negative control column
tail -n +2 $subtab | \
	cut -f $(head -1 $subtab | \
	tr "\t" "\n" | \
	grep -n "" | \
	grep -v $neg_pattern | \
	cut -d":" -f1 | \
	tr "\n" "," | \
	perl -pe 's/,$/\n/g') \
	> biol_samples_nohead.tsv

paste -d '\t' <(cut -f1 neg_ctrls_max_nohead.tsv) biol_samples_nohead.tsv \
	> max_neg_biol_samples.tsv

# remove reads from OTU if number of reads in a sample ...
# ...is smaller than the maximum negative control read number

awk -F $'\t' '{OFS=FS; m=$1; for(i=3;i<=NF;i++) if($i>m){printf("%d\t", $i)}else{printf("%d\t", "0")}; printf("\n")}' max_neg_biol_samples.tsv \
	> filtered_biol_samples_nohead.tsv

# get the OTU IDs and the header back

head -1 $subtab | \
	cut -f $(head -1 $subtab | \
	tr "\t" "\n" | \
	grep -n "" | \
	grep -v $neg_pattern | \
	cut -d":" -f1 | \
	tr "\n" "," | \
	perl -pe 's/,$/\n/g') \
	> biol_samples_header.tsv

cat biol_samples_header.tsv \
	<(paste -d $'\t' <(tail -n +2 $subtab | cut -f1) filtered_biol_samples_nohead.tsv) \
	> filtered_${subtab}
