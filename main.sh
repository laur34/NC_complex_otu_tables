#Control script

#Remove header from otu_table_0.98.txt, so that R can read it in correctly.
sed -z 's/#OTU ID\t//' otu_table_0.98.txt > otu_table_example.csv

#Run R script which takes information from the "pool" column (second column) of TSV file, to separate the OTU table into subtables (1 subtable per pool).
Rscript create_subtables.R 

#Put the hyphens back into the sample names (R can't use them) (Done in the R script)

#Apply v2_negative_controls_correction.sh on each of the above-created subtables. #### Did the script orig assume "#OTU ID" in otu tables? Because these don't have it.
#Other potential issue:  overwriting of intermediate files as v2 script is called repeatedly in loop

for file in subtable*.csv; do
    ./v2_negative_controls_correction.sh "neg" "$file"
done


#Add header to first (OTU) columns for joining
#sed -z -i 's/^/ID/' filtered_subtable*.csv

#NUMFLDS=$(awk "{print NF}" filez.tmp | head -n1)

#Paste the filtered subtables together.
arr=(filtered_subtable*.csv)
#file="${arr[1]}"
file="${arr[0]}"

for f in "${arr[@]:1}"; do
    paste "$file" <(cut -d$'\t' -f2- "$f") > _file.tmp && mv _file.tmp file.tmp
    file=file.tmp
done

#Add first cell to header, and then even it out with column -t:
sed -z 's/^/ID/' file.tmp > filez.tmp
sed 's/\t\t/\/g' filez.tmp > filtered_tbl_all.csv
#sed -i 's/\t\t/\t/g' filez.tmp

#column -t filez.tmp > filtered_tbl_all.csv
#column -c $NUMFLDS filez.tmp > filtest.csv
#other way:
#tmp=$(mktemp)
#files=(filtered_subtable*.csv)

#cp "${files[0]}" filtered_tbl_all.csv
#for file in "${files[@]:1}"; do
#    join --nocheck-order filtered_tbl_all.csv "$file" | column -t > "$tmp" && mv "$tmp" filtered_tbl_all.csv
#done

rm f*.tmp
#Remove OTUs with zero reads overall.


