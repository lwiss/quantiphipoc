##########################
#	Bucket Taxonomy		 #
##########################

Raw databases:
We have uploaded 3 different databases to GCP bucket and they are structured as follow:
1- SpeechDat High German database (in the original format as it was purchased)
	- DE-FixNetSpeechDat: Was gathered through the fixed network
	- DE-Mobil1DE-1000: Was gathered through the mobile network
	 

2- SpeechDat Swiss German database (in the original format as it was purchased): Swiss germans reading high german text i.e. swiss accented high german. Therefore there are no out of vocabulary words. 
	- SG-FixNetSpeechDat: Was gathered through the fixed network
	- SG-Polyphone: Was gathered through the mobile network
Check the README.TXT to get an understanding of every database structure. The location of the README.TXT is not consistent, it can be at the root folder or in one or multiple subfolder.

3- Junior Entreprise: Data coming from the Swiss National TV

Important:
Every database comes with it's own audio encoding/format. Thus, to make further use of the database easier, we have added along with every database an audio folder containg the speech files in wav format, 8Khz, 16bits, Microsoft PCM encoding which corresponds to telephone quality. 

%%%%%%%%TODO%%%%%%%%%
Write readme for JE data 


#############################
#	Data Preparation        #
#############################
A- Code 
Checkout this repo
%%%%%%%%TODO%%%%%%%%%
Put code in a repo and upload to git
create readme
%%%%%%%%%%%%%%%%%%%%%
B- Important notice regarding the databases

