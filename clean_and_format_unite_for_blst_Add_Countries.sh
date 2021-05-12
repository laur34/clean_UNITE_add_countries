# Create a BLAST database file from UNITE release.
# 3.5.2021 LH  #11.5.2021 LH - Adding of GBIF country info

# First, remove unidentified sequences:
sed  '/>unidentified/,+1 d' ../sh_general_release_dynamic_all_04.02.2020.fasta > sh_general_release_dynamic_all_no_unident_04.02.2020.fasta

# Next, remove duplicates
java -jar ~/Downloads/COI_classifier/rdp_classifier_2.12/dist/classifier.jar rm-dupseq -d -i sh_general_release_dynamic_all_no_unident_04.02.2020.fasta -o unite.fasta

# Then, put the IDs on the left of the headers, right afer the >'s, and then a space, and then the rest.
## Remove species at beginning, because they are also on the end anyway
#sed -i 's/^>[^|]*|/>/' unite.fasta
## Replace first pipe with space
#sed -i 's/|/\t/' unite.fasta

#### Adding country info from GBIF
#add pipes to ends of fasta header lines:
awk '{if ($1 ~ /^>/) {print $0"|"} else {print $0}}' unite.fasta > unite_pi.fasta

#remove tabs which are now in headers before the above added pipe symbols.
sed -i 's/\t//g' unite_pi.fasta

#add Fungi country information, need previously created file called fungi_species_countries_grouped.tsv:
cat unite_pi.fasta | while read line
do
    if [[ "$line" =~ k__Fungi* ]]; then
        echo -n "$line"
        F1=$(cut -f1 -d"|" <<< "$line")
        FUNGAL_SPECIES=$(echo "$F1" | cut -d">" -f 2)
        grep $FUNGAL_SPECIES fungi_species_countries_grouped.tsv
        if ! grep -q $FUNGAL_SPECIES fungi_species_countries_grouped.tsv; then
            echo
        fi
    else
        echo "$line"
    fi
done > unite_pi_fungal_spp_countries.fasta
####

#Substitute spaces introduced into fasta headers with semicolons:
#sed -i 's/ /;/' unite_pi_fungal_spp_countries.fasta

#add Plantae country information, need previously created file called plant_species_countries_grouped.tsv:
cat unite_pi_fungal_spp_countries.fasta | while read line
do
    if [[ "$line" =~ k__Viridiplantae* ]]; then
        echo -n "$line"
        F1=$(cut -f1 -d"|" <<< "$line")
        PLANT_SPECIES=$(echo "$F1" | cut -d">" -f 2)
        grep -F $PLANT_SPECIES plant_species_countries_grouped.tsv
        if ! grep -q -F $PLANT_SPECIES plant_species_countries_grouped.tsv; then
            echo
        fi
    else
        echo "$line"
    fi
done > unite_fungal_plant_spp_countries.fasta

#Substitute spaces introduced into fasta headers with pipe symbols:
sed 's/ /|/' unite_fungal_plant_spp_countries.fasta > unite_fungal_plant_spp_countries.nospc.fasta

### Rearrange headers and put spaces after the IDs.
## Remove species at beginning (those with countries also have species names before the countries)
sed -i 's/^>[^|]*|/>/' unite_fungal_plant_spp_countries.nospc.fasta
## Replace first pipe with space
sed 's/|/\t/' unite_fungal_plant_spp_countries.nospc.fasta > unite_fungal_plant_spp_countries.nospc.tab.fasta

###### There is an issue with the second word of species' binomena which begin with "sp", getting shortened to just "sp":
'''
>KF206482	SH1548969.08FU|reps|k__Fungi;p__Glomeromycota;c__Glomeromycetes;o__Diversisporales;f__Acaulosporaceae;g__Acaulospora;s__Acaulospora_sp|Acaulospora_spinosa|AR
'''
##This was caused by the grepping for fungal/plant species names, which gave positive results for e.g. "Acaulospora_sp" in "Acaulospora_spinosa"
##thereby adding the name and countires of the latter.
##TODO: Change grepping for species names in order to add country info, to only do the ones with a species binomen (i.e. are not blah_sp). 
##Acutally that make the loops even more complicated. Maybe it would be better to just delete afterwards the countries from lines containing s__blah_sp|
#######edit: SOLVED.

#if species|countries, get rid of the species right before countries.
awk 'BEGIN{FS="|";OFS="|"};{if (NF>=5) {!($4="");print} else{print $0} }' unite_fungal_plant_spp_countries.nospc.tab.fasta > unite_fungal_plant_spp_countries.nospc.tab.34pi.fasta
#(but that leaves empty field)

#if matches ">*|*|*|EOL", add a 4th | before EOL
awk 'BEGIN{FS="|";OFS="|"};{if (NF==4) {print $1,$2,$3,"|"} else{print $0} }' unite_fungal_plant_spp_countries.nospc.tab.34pi.fasta > unite_fungal_plant_spp_countries.nospc.tab.5plfld.fasta

#if matches "s__*_sp|" then remove all printing characters after ||
sed -e 's/\(s__[A-Z][a-z]*_sp||\).*$/\1/' unite_fungal_plant_spp_countries.nospc.tab.5plfld.fasta > unite_blastdb.fasta

#mv unite_blastdb.fasta unite_all_cleaned_04_2020_wcountries.fasta


