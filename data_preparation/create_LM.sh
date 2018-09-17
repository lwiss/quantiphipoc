#!/bin/bash

# Copyright 2016 SpeechLab at FEE CTU Prague (Author: Petr Mizera)
# Apache 2.0
# Note: This file was inspired by vystadial_cz/s5/local/create_LMs.sh
# Copyright 2018 DNA group at Swisscom (Author: Wissem Allouchi)

. ./cmd.sh
#. ./path.sh

cmd="run.pl"

# Setup of LMs -----------------------------------------------------------------------------------------
order='4'                # order of created LM '2' '3'
#order='4'                # order of created LM '2' '3'
smoothing='-kndiscount'  # smoothing '-kndiscount' '-wbdiscount' '-gtdiscount' without specifying default is Good-Turing
interpolate='-no'        # '-yes', '-no'

#settings for minimal count of ngrams that will appear in created LM e.g. '-gt2min3' will result in
#excluding 2grams with count lower than 3 from LM defaultly ngrams of order >=3 will be omitted if their
#count is lower than 2 '-gt1min 1 -gt2min 1 -gt3min 1'
gtmin='-gt1min 1 -gt2min 1 -gt3min 1'
#gtmin='-gt1min 1 -gt2min 1 -gt3min 1 -gt4min 1'
#nameLM="lm_order_${order}_smoothing${smoothing}_interpolate${interpolate}_gtmin${gtminname}"
nameLM="${order}gram_lm_tg"
#-------------------------------------------------------------------------------------------------------

. ./utils/parse_options.sh

input_text=$1     # data/local/train/text.lm
dir=$2            # data/local/lm

gtminname=`echo $gtmin | sed -e "s/ /-/g" -e "s/--/-/g"`

[ -d $dir ] && rm -r $dir
mkdir -p $dir

(
echo "input_text: $input_text"
echo "order: $order"
echo "gtmin: $gtmin"
echo "smoothing: $smoothing"
echo "interpolate: $interpolate"
) > $dir/$nameLM.setup

interpolatem=$interpolate;
[ $smoothing == "-goodturing" ] && smoothing="";
[ $interpolatem == "-no" ] && interpolate="";
[ $interpolatem == "-yes" ] && interpolate='-interpolate';

$SRILM/bin/i686-m64/ngram-count -text $input_text -sort -order $order $gtmin -unk -map-unk "<unk>" $smoothing $interpolate -debug 1 -lm $dir/$nameLM.gz 2>$dir/$nameLM.log

echo "ngram-count -text $input_text -sort -order $order $gtmin $smoothing $interpolate -debug 1 -lm $dir/$nameLM.gz" >> $dir/$nameLM.setup
echo "LM was created: $dir"
