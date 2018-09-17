#!/bin/bash

# Copyright 2016 SpeechLab at FEE CTU Prague (Author: Jiri Fiala, Petr Mizera)
# Apache 2.0

. ./cmd.sh
. ./path.sh

. ./utils/parse_options.sh

if [ $# -ne 1 ]; then
   echo "provide name of database"
   exit 1;
fi

database=$1
stage=2
clean_with_asrt=0

input_dir=`pwd`/export/corpora/$database
output_dir=`pwd`/data/$database/local
mkdir -p ${output_dir}

if [ $stage -le 1 ]; then
  echo executing stage 1
  # get transcription and audio from different disks
  for disk in `ls ${input_dir}`; do 
    cat ${input_dir}/$disk/transcriptions.txt >> ${input_dir}/all_text.txt
    cat ${input_dir}/$disk/idToSpeakers.txt >> ${input_dir}/all_utt2spk.txt
    awk -v var=${input_dir}/$disk '{$2=""var""$2""}1' ${input_dir}/$disk/idToRecordingPaths.txt >> ${input_dir}/all_wav.scp
  done 
fi

if [ $clean_with_asrt -eq 1 ]; then
  # this step is performed locally since no asrt version is running on aws
  python2.7 run_data_preparation.py -i /Users/taaalwi1/Documents/speech/aiml-recipes/all_text_without_ids.txt -o /Users/taaalwi1/Documents/speech/aiml-recipes/all_text_without_ids_cleaned_asrt.txt -l 2  -r /Users/taaalwi1/Documents/speech/asrt/examples/resources/regex.csv -m -n -s
fi
# Generate utt2spk 
cp ${input_dir}/all_utt2spk.txt ${output_dir}/all.utt2spk


if [ $stage -le 2 ]; then
  echo executing stage 2
  # Generate path to wav files and Create wav files if they don't exist
  output_audio_dir=${input_dir}/audio/08k_16b
  mkdir -p ${output_audio_dir}
  awk '{print $0;}' ${input_dir}/all_wav.scp | perl -snle '$line = $_; $line =~ s/\/home\/ubuntu\/efs\/wissem\/aiml-recipes\/gsw_je_model_adaptation\/v1\/export\/corpora\/je-schweiz-aktuell\/je-transcriptions-1-schweiz-aktuell-disk\d_de-ch\/recordings/$d/g; print $line;' -- -d=${output_audio_dir} > ${output_dir}/all_wav_8k_16b.scp
  paste ${input_dir}/all_wav.scp ${output_dir}/all_wav_8k_16b.scp | awk '{print $2,$4}' > ${output_dir}/sox.scp
  # awk '{cmd="sox -t wav -r 44100  -c 2 " $1 " -t wav -r 8000 -e signed-integer -c 1 " $2; system(cmd)}' ${output_dir}/sox.scp
fi

if [ $stage -le 3 ]; then
  echo executing stage 3
  # create uttreance id mapping 
  awk '{$3=$2"-"$1; print $1,$3,$2}' ${output_dir}/all.utt2spk > ${output_dir}/utt_map
  # map and sort
  ./local/apply_utt_mapping.py ${output_dir}/utt_map ${output_dir}/all_wav_8k_16b.scp ${output_dir}/all_wav_8k_16b_mapped.scp
  ./local/apply_utt_mapping.py ${output_dir}/utt_map ${input_dir}/all_text_clean_asrt.txt ${output_dir}/text_mapped 
  ./local/apply_utt_mapping.py ${output_dir}/utt_map ${output_dir}/all.utt2spk ${output_dir}/all.utt2spk_mapped
  sort -u ${output_dir}/all_wav_8k_16b_mapped.scp > ${output_dir}/all_wav_8k_16b_mapped_sorted.scp
  sort -u ${output_dir}/text_mapped  > ${output_dir}/all_text_mapped_sorted
  sort -u ${output_dir}/all.utt2spk_mapped > ${output_dir}/all.utt2spk_mapped_sorted
  
  # Final cleaning 
  mv ${output_dir}/all_wav_8k_16b_mapped_sorted.scp ${output_dir}/wav.scp
  mv ${output_dir}/all_text_mapped_sorted ${output_dir}/text
  mv ${output_dir}/all.utt2spk_mapped_sorted ${output_dir}/utt2spk
  perl utils/utt2spk_to_spk2utt.pl ${output_dir}/utt2spk | sort -u > ${output_dir}/spk2utt
fi

echo Cleanup... 
rm -f ${output_dir}/all* ${output_dir}/sox.scp 

echo $database " ... data preparation done successfully"
