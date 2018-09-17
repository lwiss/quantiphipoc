#!/bin/bash

# Copyright 2016 SpeechLab at FEE CTU Prague (Author: Jiri Fiala, Petr Mizera)
# Apache 2.0

. ./cmd.sh
. ./path.sh

. ./utils/parse_options.sh

if [ $# -le 1 ]; then
   echo "provide name of database and if it is fixnet or mobile"
   exit 1;
fi

database=$1
mob_or_fix=$2
language=$3

input_dir=`pwd`/export/corpora/$database
output_dir=`pwd`/data/$database/local
mkdir -p ${output_dir}

if [ ${mob_or_fix} == "fix"  ] && [ $language == "SZ" ]; then
  content_table=$input_dir/Dsk3/FIXED1SZ/INDEX/CONTENTS.LST
  input_audio_dir=$input_dir/Dsk3/FIXED1SZ
  output_audio_dir=$input_dir/Dsk3/FIXED1SZ/audio/08k_16b
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ];then 
  content_table=$input_dir/Disks/CONTENTS.LST.iso
  input_audio_dir=$input_dir
  output_audio_dir=$input_dir/audio/08k_16b

elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  # merge content tables from individual disk into 
  content_table=$input_dir/CONTENTS.LST
  echo -e "VOL\tDIR\tSRC\tSCD\tSEX\tAGE\tACC\tLBO" > $content_table
  for disk in `ls ${input_dir} | grep Dsk`; do 
    cat $input_dir/$disk/FIXED0DE/INDEX/CONTENTS.LST | awk -v var=$disk '{$2=""var""$2""}1' | perl -pe 's/ /\t/g'>> $content_table 
  done 
  input_audio_dir=$input_dir
  output_audio_dir=$input_dir/audio/08k_16b
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  content_table=$input_dir/Dsk1/MOBIL1DE/INDEX/CONTENTS.LST
  input_audio_dir=$input_dir
  output_audio_dir=$input_dir/audio/08k_16b
fi


# Filtering utterances with word truncations, mispronunciations, non-understandable speech (around 13% is removed!!!!!!!!)
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then
  tail -n +2 ${content_table} | perl -nle '@a=split;$line=join "\t",@a;$_=join " ",@a[8..@a]; if(!/\.|~|\*|\%|\-|\/|\_/){ print $line}' > ${output_dir}/filtered_content
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then 
  tail -n +2 ${content_table} | perl -nle '@a=split;$audio_path=$a[0];$line=join " ",@a[1..@a];$_=join " ",@a[1..@a]; if(!/~|\*|\%|\-|\/|\_/){ print $audio_path . "\t"  . $line}' > ${output_dir}/filtered_content
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  tail -n +2 ${content_table} | perl -nle '@a=split;$line=join "\t",@a;$_=join " ",@a[7..@a]; if(!/\.|~|\*|\%|\-|\/|\_/){ print $line}' > ${output_dir}/filtered_content
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  tail -n +2 ${content_table} | perl -nle '@a=split;$line=join "\t",@a;$_=join " ",@a[8..@a]; if(!/\.|~|\*|\%|\-|\/|\_/){ print $line}' > ${output_dir}/filtered_content
fi
iconv -f ISO-8859-15 -t UTF-8 ${output_dir}/filtered_content > ${output_dir}/filtered_content_utf8
cp ${output_dir}/filtered_content ${output_dir}/filtered_content_iso
mv ${output_dir}/filtered_content_utf8 ${output_dir}/filtered_content

# Get speaker gender
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then
  cut -d$'\t' -f6,7 ${content_table} | tail -n +2 > ${output_dir}/all.gender
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then
  cut -d$'\t' -f1 ${content_table} | tail -n +2 | tr -d '\r' | cut -c4-7 | perl -nle '$sess=$_; $block = substr $sess,0,2;  $line=$sess .  "\tBLOCK" . $block  . "/SES" . $_ . "/SZ" . $_ . ".TXT";  if ($line =~ /BLOCK\d/) {print $line}'  > ${output_dir}/all.gender
  awk '!x[$0]++' ${output_dir}/all.gender | awk  -v var=${input_dir} '{print $1, ""var"/"$2"" }' | awk '{"cat " $2 "| grep Sex" |  getline s; gsub(/Sex: male/,"m",s);gsub(/Sex: female/,"f",s);print $1 "\t" s }' > ${output_dir}/all.gender_no_dublicates 
  mv ${output_dir}/all.gender_no_dublicates ${output_dir}/all.gender
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  cut -d$'\t' -f4,5 ${content_table} | tail -n +2 > ${output_dir}/all.gender
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  cut -d$'\t' -f6,7 ${content_table} | tail -n +2 | tr -d '\r' | awk '{$1=substr($1,3,4)}1'> ${output_dir}/all.gender
fi 
awk '!x[$0]++' ${output_dir}/all.gender > ${output_dir}/all.gender_no_dublicates
rm ${output_dir}/all.gender
mv ${output_dir}/all.gender_no_dublicates ${output_dir}/all.gender
sort -u ${output_dir}/all.gender | tr '[:upper:]' '[:lower:]'  > ${output_dir}/all.gender.new
mv ${output_dir}/all.gender.new ${output_dir}/all.gender

# Get all session (each session corresponds to one speaker)
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then
  cut -d$'\t' -f6 ${content_table} | tail -n +2 | tr -d '\r' > ${output_dir}/all.ses
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then
  cut -d$'\t' -f1 ${content_table} | tail -n +2 | tr -d '\r' | cut -c4-7 > ${output_dir}/all.ses
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  cut -d$'\t' -f4 ${content_table} | tail -n +2 | tr -d '\r' > ${output_dir}/all.ses
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  cut -d$'\t' -f6 ${content_table} | tail -n +2 | tr -d '\r' | awk '{$1=substr($1,3,4)}1' > ${output_dir}/all.ses
fi
awk '!x[$0]++' ${output_dir}/all.ses > ${output_dir}/all_no_duplicates.ses
rm ${output_dir}/all.ses
mv ${output_dir}/all_no_duplicates.ses ${output_dir}/all.ses
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then
  # Adding "A1" in the names of the speakers because the grep creates a problem without A1 infront of the speaker's ID number
  awk '{print "A1"$0}' ${output_dir}/all.ses > ${output_dir}/all.ses_renamed1
  cut -d$'\t' -f3  ${output_dir}/filtered_content | sed s/.${language}A//g | grep -f ${output_dir}/all.ses_renamed1 \
          | awk '{print $1," " substr ($1, 3, 4)}' | sort -u > ${output_dir}/all.utt2spk
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then
  # Adding "SZ" in the names of the speakers because the grep creates a problem without SZ infront of the speaker's ID number
  awk '{print "SZ"$0}' ${output_dir}/all.ses > ${output_dir}/all.ses_renamed1
  cut -d$'\t' -f1  ${output_dir}/filtered_content | tr -d '\r' | cut -c9-16 | grep -f ${output_dir}/all.ses_renamed1 \
          | awk '{print $1," " substr ($1, 3, 4)}' | sort -u > ${output_dir}/all.utt2spk
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  # Adding "A0" in the names of the speakers because the grep creates a problem without A0 infront of the speaker's ID number
  awk '{print "A0"$0}' ${output_dir}/all.ses > ${output_dir}/all.ses_renamed1
  cut -d$'\t' -f3  ${output_dir}/filtered_content | sed s/.${language}Z//g | grep -f ${output_dir}/all.ses_renamed1 \
          | awk '{print $1," " substr ($1, 3, 4)}' | sort -u > ${output_dir}/all.utt2spk
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  # Adding "B1" in the names of the speakers because the grep creates a problem without B1 infront of the speaker's ID number
  awk '{print "B1"$0}' ${output_dir}/all.ses > ${output_dir}/all.ses_renamed1
  cut -d$'\t' -f3  ${output_dir}/filtered_content | sed s/.${language}A$//g | grep -f ${output_dir}/all.ses_renamed1 \
          | awk '{print $1," " substr ($1, 3, 4)}' | sort -u > ${output_dir}/all.utt2spk
fi

# Generate utt2spk and spk2utt
perl utils/utt2spk_to_spk2utt.pl ${output_dir}/all.utt2spk | sort -u > ${output_dir}/all.spk2utt

# Generate path to wav files and Create wav files if they don't exist
awk '{print "SES"$0}' ${output_dir}/all.ses > ${output_dir}/all.ses_renamed2
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then

  cut -d$'\t' -f2,3 ${output_dir}/filtered_content | tr '\t' '/' | sed 's/\\/\//g' | sed 's/^\/FIXED...\///g' | sed 's/SZA/wav/g' | grep -f ${output_dir}/all.ses_renamed2 \
          | awk -v var=${output_audio_dir} '{print ""var"/"$1""}' \
          | sort -u > ${output_dir}/all.ses.scp
  paste ${output_dir}/all.utt2spk ${output_dir}/all.ses.scp | awk '{$2=""; print $0}' > ${output_dir}/all.scp
  awk '{print $2}' ${output_dir}/all.scp | sed 's,'"${output_audio_dir}"','"${input_audio_dir}"',g' | sed s/wav/SZA/g > ${output_dir}/all.original.scp
  awk '{print $1}' ${output_dir}/all.ses.scp | xargs dirname | xargs mkdir -p
  paste ${output_dir}/all.original.scp ${output_dir}/all.ses.scp | awk '{cmd="sox -t raw -r 8000 -e a-law -c 1 " $1 " -t wav -r 8000 -e signed-integer -c 1 " $2; system(cmd)}'
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then

  cut -d$'\t' -f1 ${output_dir}/filtered_content | tr -d '\r' | awk '{print "BLOCK" substr($1, 4, 2) "/" $1}' | sed 's/ALW/wav/g' | grep -f ${output_dir}/all.ses_renamed2 \
          | awk -v var=${output_audio_dir} '{print ""var"/"$1""}' \
          | sort -u > ${output_dir}/all.ses.scp 
  paste ${output_dir}/all.utt2spk ${output_dir}/all.ses.scp | awk '{$2=""; print $0}' > ${output_dir}/all.scp
  awk '{print $2}' ${output_dir}/all.scp | sed 's,'"${output_audio_dir}"','"${input_audio_dir}"',g' | sed s/wav/ALW/g > ${output_dir}/all.original.scp
  awk '{print $1}' ${output_dir}/all.ses.scp | xargs dirname | xargs mkdir -p
  paste ${output_dir}/all.original.scp ${output_dir}/all.ses.scp | awk '{cmd="sph2pipe -f wav  " $1 " > " $2; system(cmd)}'
  awk '{cmd="sox -t raw -r 8000 -e a-law -c 1 " $2 " -t wav -r 8000 -e signed-integer -c 1 " $2".new"; system(cmd)}' ${output_dir}/all.ses.scp
  awk '{cmd="mv " $2".new "$2; system(cmd)}' ${output_dir}/all.ses.scp
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then

  cut -d$'\t' -f2,3 ${output_dir}/filtered_content | tr '\t' '/' | sed 's/\\/\//g' | sed 's/DEZ/wav/g' | grep -f ${output_dir}/all.ses_renamed2 \
          | awk -v var=${output_audio_dir} '{print ""var"/"$1""}' \
          | sort -u > ${output_dir}/all.ses.scp
  awk '{print substr($1, length($1) - 11, 8),$1}' ${output_dir}/all.ses.scp  > ${output_dir}/all.scp
  awk '{print $2}' ${output_dir}/all.scp | sed 's,'"${output_audio_dir}"','"${input_audio_dir}"',g' | sed s/wav/DEZ/g > ${output_dir}/all.original.scp
  awk '{print $1}' ${output_dir}/all.ses.scp | xargs dirname | xargs mkdir -p
  cat ${output_dir}/all.original.scp | sed 's/DEZ/gz/g' > ${output_dir}/all.original_renamed.scp
  paste ${output_dir}/all.original.scp ${output_dir}/all.original_renamed.scp | awk '{cmd="cp " $1 " " $2; system(cmd); cmd="gzip -d " $2; system(cmd)}'
  cat ${output_dir}/all.original_renamed.scp | sed 's/\.gz//g' > ${output_dir}/all.original.scp
  paste ${output_dir}/all.original.scp ${output_dir}/all.ses.scp | awk '{cmd="sox -t raw -r 8000 -e a-law -c 1 " $1 " -t wav -r 8000 -e signed-integer -c 1 " $2; system(cmd)}'

elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  cut -d$'\t' -f2,3 ${output_dir}/filtered_content | tr '\t' '/' | sed 's/\\/\//g' | sed 's/DEA/wav/g' | grep -f ${output_dir}/all.ses_renamed2 \
          | awk -v var=${output_audio_dir} '{print ""var""$1""}' \
          | sort -u > ${output_dir}/all.ses.scp
  paste ${output_dir}/all.utt2spk ${output_dir}/all.ses.scp | awk '{$2=""; print $0}' > ${output_dir}/all.scp
  awk '{print $2}' ${output_dir}/all.scp | sed 's,'"${output_audio_dir}"','"${input_audio_dir}"',g' | sed s/wav/DEA/g > ${output_dir}/all.original.scp
  awk '{print $1}' ${output_dir}/all.ses.scp | xargs dirname | xargs mkdir -p
  paste ${output_dir}/all.original.scp ${output_dir}/all.ses.scp | awk '{cmd="sox -t raw -r 8000 -e a-law -c 1 " $1 " -t wav -r 8000 -e signed-integer -c 1 " $2; system(cmd)}'
fi

# Get transcriptions  
if [ ${mob_or_fix} == "fix" ] && [ $language == "SZ" ]; then 
  perl local/speechdat_create_trans_SZ.pl ${output_dir}/all.utt2spk  ${input_dir}/Dsk3/FIXED1SZ $language | sort -k1  > ${output_dir}/all.txt 
  iconv -f ISO-8859-15 -t UTF-8 ${output_dir}/all.txt > ${output_dir}/all.txt.utf8
  mv ${output_dir}/all.txt.utf8 ${output_dir}/all.txt
  rm -rf ${output_dir}/all.txt.utf8
elif [ ${mob_or_fix} == "mobile" ] && [ $language == "SZ" ]; then
  awk '{print substr($1, 9, 8), $0}'  ${output_dir}/filtered_content | awk '{$2=""}1'  > ${output_dir}/all.txt
elif [ ${mob_or_fix} == "fix" ] && [ $language == "DE" ];then
  perl local/speechdat_create_trans.pl ${output_dir}/all.original.scp $language | sort -k1  > ${output_dir}/all.txt 
  iconv -f ISO-8859-15 -t UTF-8 ${output_dir}/all.txt > ${output_dir}/all.txt.utf8
  mv ${output_dir}/all.txt.utf8 ${output_dir}/all.txt
  rm -rf ${output_dir}/all.txt.utf8

elif [ ${mob_or_fix} == "mobile" ] && [ $language == "DE" ];then
  awk '{print $1}' ${output_dir}/all.original.scp | sed 's/\.DEA$//g' > ${output_dir}/all.original_renamed.scp
  perl local/speechdat_create_trans.pl ${output_dir}/all.original_renamed.scp $language | sort -k1  > ${output_dir}/all.txt 
  iconv -f ISO-8859-15 -t UTF-8 ${output_dir}/all.txt > ${output_dir}/all.txt.utf8
  mv ${output_dir}/all.txt.utf8 ${output_dir}/all.txt
  rm -rf ${output_dir}/all.txt.utf8
fi

# Final cleaning 
mv ${output_dir}/all.scp ${output_dir}/wav.scp
mv ${output_dir}/all.txt ${output_dir}/text
mv ${output_dir}/all.utt2spk ${output_dir}/utt2spk
mv ${output_dir}/all.spk2utt ${output_dir}/spk2utt
mv ${output_dir}/all.gender ${output_dir}/spk2gender

rm -f ${output_dir}/all.* ${output_dir}/filtered_content*

echo $database " ... data preparation done successfully"
