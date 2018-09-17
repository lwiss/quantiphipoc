
#	Bucket Taxonomy	


### Raw databases:
We have uploaded 3 different databases to GCP bucket and they are structured as follow:

    1- SpeechDat High German database (in the original format as it was purchased)
	    - DE-FixNetSpeechDat: Was gathered through the fixed network
	    - DE-Mobil1DE-1000: Was gathered through the mobile network
	 

    2- SpeechDat Swiss German database (in the original format as it was purchased): Swiss germans reading high german text i.e. swiss accented high german. Therefore there are no out of vocabulary words. 
	    - SG-FixNetSpeechDat: Was gathered through the fixed network
	    - SG-Polyphone: Was gathered through the mobile network


    3- Junior Entreprise: Data coming from the Swiss National TV

Check the README.TXT to get an understanding of every database structure. The location of the README.TXT is not consistent, it can be at the root folder or in one or multiple subfolder.

#### Important:
Every database comes with it's own audio encoding/format. Thus, to make further use of the data easier, we have added along with every database an audio folder containg the speech files in wav format, 8Khz, 16bits, Microsoft PCM encoding which corresponds to telephone quality. 
 

#	Data Preparation       

Here are some notes from our work with the SpeechDat databases

- DE-CH (speech files are in a-law format (compressed?))
- FixNet: Dsk1 and Dsk2 are ducplicated since they are contained in SG-polyphone --> use only Dsk3 
- Polyphone: contains Block00 till Block39 but transcripts available for everything exept Block13 to Block24
- To ease the treatment for Polyphone a CONTENTS.LST combining all the individual LST files was created manually (easier than accounting for all the variation in the naming conventions)

- Rename CD02 to CD00 for DE-DE Fixed diks3
- for DE-DE Mobile: all blocks are moved to MOBIL1DE (to make the data prep script easier)


Remarks data preparation:
1. filter out utterances with word truncations, mispronunciations, non-understandable speech 
2. when applying copydatadir on the different databases spk2gender causes problems --> romoved it, since it won't affect the training 
3. when applying copydatadir on the different databases the text file created some issues (ending with white space, first line is wrong) --> since they were only a few of them --> corrected them manually

