# Pre-Processing PIRE Data

List of steps to take in raw fq files from shotgun and capture-shotgun

testing permission

---


<details><summary>Before You Start, Read This</summary>
<p>

## Before You Start, Read This

The purpose of this repo is to provide the steps for processing raw fq files for both [Shotgun Sequencing Libraries - SSL data](https://github.com/philippinespire/pire_ssl_data_processing) for probe development and the [Capture Shotgun Sequencing Libraries- CSSL data](https://github.com/philippinespire/pire_cssl_data_processing).

Scripts with `ssl` in the name are designed for shotgun data, including `lcwgs`. Scripts with `cssl` in the name are designed for capture-shotgun data. Scripts with no suffix in the name can be used for both types of data. Both the the `pire_ssl_data_processing` and `pire_cssl_data_processing` and `pire_lcwgs_data_processing` repos assume that the `pire_fq_gz_processing` repo is in the same directory as they are.  

---

</p>
</details>


<details><summary>Which HPC Are You Using?</summary>
<p>

## Use Turing

We encourage everybody to use `wahab.hpc.odu.edu` or `turing.hpc.odu.edu`, preferably wahab.  You can start by logging onto wahab

	```bash
	ssh YourUserName@wahab.hpc.odu.edu
	```

There are shared repos on wahab and turing in `/home/e1garcia/shotgun_PIRE` that you are encouraged to use.

	```bash
	cd /home/e1garcia/shotgun_PIRE
	```

If, however, you know that you deliberately don't want to use the shared repos on wahab and turing in `/home/e1garcia/shotgun_PIRE`, then here is how you would get started on another hpc and realize that you will have to modify all of the paths given in these `README.md` and tutorials.

**ONLY DO THE FOLLOWING STEPS 0 AND 1 IF YOU ARE NOT USING WAHAB OR TURING**

0. Create a directory for your PIRE repos to live in, and cd into it

	```bash
	mkdir <pathToPireDir>
	cd <pathToPireDir>
	```

1. Clone the repos into your PIRE working dir 

	```sh
	#cd to your working dir then
	git clone https://github.com/philippinespire/pire_fq_gz_processing.git

	# then choose which repo you are using
	git clone https://github.com/philippinespire/pire_ssl_data_processing.git
	git clone https://github.com/philippinespire/pire_cssl_data_processing.git
	git clone https://github.com/philippinespire/pire_lcwgs_data_processing.git
	```

---

</p>
</details>

<details><summary>Git Your Act Together or Be Doomed to a Life of Anguish and Despair</summary>
<p>

## Git etiquette 

You must constantly be pulling and pushing changes to github with `git` or else you're going to mess up the repo.

1. Goto your PIRE working dir (`/home/e1garcia/shotgun_PIRE` on wahab) and use the `pire_fq_gz_processing` repo along with either `pire_ssl_data_processing` or `pire_cssl_data_processing` or `pire_lcwgs_data_processing`, and immediately start by pulling changes from github in the repos you are using **EACH TIME YOU LOG IN**

	```bash
	# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
	cd <yourPireDirPath>/pire_fq_gz_processing
	git pull

	# replace <ssl or cssl or lcwgs> with either ssl or cssl or lcwgs, no spaces
	cd <yourPireDirPath>/pire_<ssl or cssl or lcwgs>_data_processing
	git pull
	```

2. When your session is done, i.e. you are about to log off, push your changes to github **EACH TIME YOU LOG OUT**

	```bash
	cd <yourPireDirPath>/pire_<ssl or cssl or lcwgs>_data_processing
	git pull

	# if there are no errors, then proceed, otherwise get help
	git add --all

	# if there are no errors, then proceed, otherwise get help
	git commit -m "insert message here"

	# if there are no errors, then proceed, otherwise get help
	git push
	```

3. As you work through this tutorial it is assumed that you will be running scripts from either `pire_ssl_data_processing` or `pire_cssl_data_processing` or `pire_lcwgs_data_processing` and you will need to add the path to the `pire_fq_gz_processing` directory before the script's name in the code blocks below.

	```sh
	#add this path when running scripts on wahab
	#<yourPireDirPath>/pire_fq_gz_processing/<script's name> <script arguments>

	#Example:
	sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh <script arguments>
	```

---

</p>
</details>


<details><summary>Overview</summary>
<p>

## Overview

***Download data, rename files, trim, deduplicate, decontaminate, and repair the raw `fq.gz` files***
*(plan for a few hours for each step except for decontamination, which can take 1-2 days)*

Scripts to run
  * [gridDownloader.sh](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/gridDownloader.sh)
  * [renameFQGZ.bash](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/renameFQGZ.bash)
  * [Multi_FASTQC.sh](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/Multi_FASTQC.sh)
  * [runFASTP_1st_trim.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_1st_trim.sbatch)
  * [runCLUMPIFY_r1r2_array.bash](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runCLUMPIFY_r1r2_array.bash)
  * [runFASTP_2_ssl.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_2_ssl.sbatch) | [runFASTP_2_cssl.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_2_cssl.sbatch)
  * [runFQSCRN_6.bash](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFQSCRN_6.bash)
  * [runREPAIR.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runREPAIR.sbatch)
  
    * open scripts for usage instructions
    * review the outputs from `fastp`, `fastq_screen`, and `repair` with `MultiQC` output

---

</p>
</details>


<details><summary>0. Set up directory for species if it doesn't exist</summary>
<p>

## 0. Set up directory

All types of data will share the following directories associated with data qc

```bash
# if it does not exist, make the directory for your species 
# you must replace the <> with the real val
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
mkdir <yourPireDirPath>/pire_<ssl or cssl or lcwgs>_data_processing/<genus_species>
cd <yourPireDirPath>/pire_<ssl or cssl or lcwgs>_data_processing/<genus_species>
mkdir fq_raw fq_fp1 fq_fp1_clmp fq_fp1_clmp_fp2 fq_fp1_clmp_fp2_fqscrn fq_fp1_clmp_fp2_fqscrn_rprd
```

---

</p>
</details>


<details><summary>1. Download data</summary>
<p>

## **1. Download your data from the TAMUCC grid**

**Locate the link to the files**. This is provided by Sharon at the species slack channel once the data is ready to be downloaded.  Make sure it works: click on it and your web browser should open listing your data files.
e.g. [https://gridftp.tamucc.edu/genomics/20221011_PIRE-Gmi-capture](https://gridftp.tamucc.edu/genomics/20221011_PIRE-Gmi-capture).

Check that you can see a file named "tamucc_files.txt" along with the decode and fq files. This script will not work without this file. Click on the "tamucc_files.txt" to see its contents. If this has only 1 column with the file names (i.e. it was created with a simple ls), this script will download the files but will not be able to check the size of files before and after download. Yet, you can visually check the size of files before (in the web browser) and after (in the HPC). If "tamucc_files.txt" has 9 columns (i.e. it was created with a ls -ltrh), this will download the files and will automatically check the size of files before and after download. If you have many files and your "tamucc_files.txt" has only 1 column, it might be worth asking Sharon or someone at TAMUCC to recreate it with an ls -ltrh.

```bash
# Navigate to dir to download files into, e.g.
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/fq_raw

# sbatch gridDownloader.sh <outdir> <link-to-files>
# outdir becomes "." since you have already navigated there
sbatch <yourPireDirPath>/pire_fq_gz_processing/gridDownloader.sh . https://gridftp.tamucc.edu/genomics/<YYYYMMDD>_PIRE-<your_species>-capture/
```

### Chek your download

**A) Check the log of `gridDownloader.sh`**

Look at the bottom of the Wget*out file. `gridDownloader.sh` will write this message *"No size mismatch in files was detected"* if no issues were found, or *"Files with different sizes detected. Offending file(s) printed in files_wDiff_sizes. Please check files_wDiff_sizes and compare tamucc_files.txt with current downloaded data"* if the script detected issues. The script automatically will restart the download of the files in `files_wDiff_sizes` but you should compare the size of these files visually in the web browser and your downloads.

If your download fails completely, go back to the web browser and check that you can see a file named "tamucc_files.txt" along with the decode and fq files. 

`*1.fq.gz` files contain the forward reads and `*2.fq.gz` files contain the reverse reads for an individual. Every individual should have one of each

If everything looks normal (all files were downloaded and no different sizes detected), move to step B.

**B) Check the zip and fastq formats of your files with `checkFQ.sh`**

Even though gridDownloader.sh checks the size of your files, the formatting of these can still have issues.

`checkFQ.sh` will:
* Identify files with alternate zip files (a normal format is "Blocked GNU Zip Format") and list them in the file `files_w_alternative_zip_format.txt`, and
* Identify files where one or more sequences don't have a proper fastq format (4 lines per sequence) and list them in the file `files_w_bad_fastq_format.txt`

You might want to redownload and/or check the format issues with the identified files. More details in the log of checkFQ.sh

Execute `checkFQ.sh` 
```sh
# sbatch checkFQ.sh <dir with fq.gz files>
sbatch <yourPireDirPath>/pire_fq_gz_processing/checkFQ.sh /home/e1garcia/shotgun_PIRE/pire_<lcwgs|cssl|ssl>_data_procssing/fq_raw/
```
Check the log and files_w_* to make sure no issues were found

---

</p>
</details>


<details><summary>2. Proofread the decode files</summary>
<p>

## **2. Proofread the decode file(s) (<1 minute run time)**

The decode file converts the file name that we had to use for NovoGene to the PIRE file name convention.

The decode file should be formatted as follows: tab separated, where the first column is the NovoGene prefix names (the prefixes of the downloaded fq.gz files, `Sequence_Name`), the second column is the PIRE name prefixes (the prefixes to apply to the files, `Extraction_ID`), the first row contains the column headers, and the rest of the columns contain the NovoGene and PIRE file prefixes.

```bash
Sequence_Name	Extraction_ID
SgA0103511C	Sgr-AMvi_035-Ex1-cssl
SgA0104307D	Sgr-AMvi_043-Ex1-cssl
SgA0104610D	Sgr-AMvi_046-Ex1-cssl
SgA0105406E	Sgr-AMvi_054-Ex1-cssl
```

Make sure you check that the following PIRE prefix naming format is followed, where there is only 1 `_` character:

`PopSampleID_LibraryID` where:

  * `PopSampleID` = `3LetterSpeciesCode-CorA3LetterSiteCode`
  * `LibraryID` = `IndiviudalID-Extraction-PlateAddress-LibType`  or just `IndividualID` if there is only 1 library for the individual 

__Do NOT use `_` in the LibraryID. *The only `_` should be separating `PopSampleID` and `LibraryID`.__

Examples of compatible names:

  * `Sne-CTaw_051-Ex1-3F-cssl-L4` = *Sphaeramia nematoptera* (Sne), contemporary (C) from Tawi-Tawi (Taw), indv 051, extraction 1, loc 3F on plate, capture lib, loc L4 (lane 4)

Here are some other QC checks on the downloaded data and the decode files:

```bash
salloc
bash

# Navigate to dir with downloaded files, e.g.
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/fq_raw

#check that you got back sequencing data for all individuals in decode file
#XX files (2 additional files for README.md & decode.tsv = XX/2 = XX individuals (R&F)
ls *1.fq.gz | wc -l 
ls *2.fq.gz | wc -l 

#XX lines (1 additional line for header = XX individuals), checks out
wc -l <NAMEOFDECODEFILE>.tsv 

#are ther duplicates of libraries?
cat <NAMEOFDECODEFILE>.tsv | sort | uniq | wc -l

```

---

</p>
</details>


<details><summary>3. Edit the decode file (if there is a formatting issue)</summary>
<p>

## **3. Edit the decode file**

If there is an issue with the formatting of the decode file, rename the original file, and create a new file to edit.

```bash
mv SequenceNameDecode.tsv SequenceNameDecode_original_deprecated.tsv
cp SequenceNameDecode_original_depricated.tsv SequenceNameDecode_fixed.tsv
```

Then edit the `SequenceNameDecode.tsv` file to conform to the file formatting rules outlined in step 2, above.

---

</p>
</details>


<details><summary>4. Make a copy of the fq_raw files prior to renaming</summary>
<p>

## **4. Make a copy of the `fq_raw` files prior to renaming (several hours run time, don't proceed to next step until this is done)**

If you haven't done so, create a copy of your raw files unmodified in the longterm Carpenter RC dir
`/RC/group/rc_carpenterlab_ngs/shotgun_PIRE/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<species_name>/fq_raw`.  
*(can take several hours)*
	
Because this can take a long time, we are going to use the `screen` command.  `screen` opens up a new terminal automatically.  You can exit that terminal by typing `ctrl-a` and then `d` to detach and return to your terminal.  Running a command inside of `screen` ensures that it runs to completion and will not end when you log out.  Using `screen` also frees up your terminal to goto the next step.  After detaching, you can run screen -ls to see the list of screen terminals that are currently running.

```bash
mkdir /RC/group/rc_carpenterlab_ngs/shotgun_PIRE/pire_<ssl|cssl|lcwgs>_data_processing/<species_name>
mkdir /RC/group/rc_carpenterlab_ngs/shotgun_PIRE/pire_<ssl|cssl|lcwgs>_data_processing/<species_name>/fq_raw

# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/fq_raw

screen cp ./* /RC/group/rc_carpenterlab_ngs/shotgun_PIRE/pire_<ssl|cssl|lcwgs>_data_processing/<species_name>/fq_raw

# `ctrl-a`  and then `d` to detach from the `screen` terminal

# look at your screen jobs running
screen -ls
```

---

</p>
</details>


<details><summary>5. Perform a renaming dry run</summary>
<p>

## **5. Perform a renaming dry run**

Then, use the decode file with [`renameFQGZ.bash`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/renameFQGZ.bash) to rename your raw `fq.gz` files. If you make a mistake here, it could be catastrophic for downstream analyses. This is why we ***STRONGLY recommend*** you use this pre-written bash script to automate the renaming process. [`renameFQGZ.bash`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/renameFQGZ.bash) allows you to view what the files will be named before renaming them and also stores the original and new file names in files that could be used to restore the original file names.

Run `renameFQGZ.bash` to view the original and new file names and create `tsv` files to store the original and new file naming conventions.

```bash
# Navigate to dir with downloaded files, e.g.
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/fq_raw

# log into a compute node interactively so this goes faster
salloc

# once you have the compute node, procede
bash <yourPireDirPath>/pire_fq_gz_processing/renameFQGZ.bash <NAMEOFDECODEFILE>.tsv 
```

**NOTE:** Depending on how you have your `.wahab_tcshrc` (or `.turing_tcshrc` if on Turing) set-up, you may get the following error when you try to execute this script: *Cwd.c: loadable library and perl binaries are mismatched (got handshake key 0xcd00080, needed 0xde00080)*. To fix this:

  1. Open up `.wahab_tcshrc` (it will be in your home (`~`) directory) and add `unsetenv PERL5LIB` at the end of the chunk of code under the `if (! $?MODULES_LOADED) then` line. One of the modules we are loading for the scripts loads a "bad" perl library that is causing the error message downstream.
  2. Save your changes.
  3. Close out of your Terminal connection and restart it. You should be able to run `renameFQGZ.bash` now without any issues.

---

</p>
</details>


<details><summary>6. Rename the files for real</summary>
<p>

## **6. Rename the files for real (<1 minute run time)**

After you are satisfied that the orginal and new file names are correct, then you can change the names. To check and make sure that the names match up, you are mostly looking at the individual and population numbers in the new and old names, and that the `-` and `_` in the new names are correct (e.g. no underscores where there should be a dash, etc.). If you have to make changes, you can open up the `NAMEOFDECODEFILE.tsv` to do so, **but be very careful!!**

Example of how the file names line up:

  * `Sne-CTaw_051` = `SnC01051` at the beginning of the original file name
    * Sn = Sne, C = C, 01 = population/location 1 if there are more than 1 populations/locations in the dataset (here Taw location), 051 = 051
    
When you are ready to change names, execute the line of code below. This script will ask you twice whether you want to proceed with renaming.

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/fq_raw

bash <yourPireDirPath>/pire_fq_gz_processing/renameFQGZ.bash <NAMEOFDECODEFILE>.tsv rename

#you will need to say y 2X
```


---

</p>
</details>


<details><summary>7. Check the quality of raw data</summary>
<p>

## **7. Check the quality of your data. Run `fastqc` (1-2 hours run time, but you can move onto the next step before this completes)**

FastQC and then MultiQC can be run using the [Multi_FASTQC.sh](Multi_FASTQC.sh) script in this repo.

Execute `Multi_FASTQC.sh` while providing, in quotations and in this order, (1) the FULL path to these files and (2) a suffix that will identify the files to be processed.

`Multi_FASTQC.sh` should be run from the directory that holds the raw, renamed `fq.gz` files. This will be `fq_raw`. If not, rename it to fq_raw

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch Multi_FASTQC.sh "<indir>" "<mqc report name>" "<file extension to qc>"
#do not use trailing / in paths. Example:
sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh "fq_raw" "fqc_raw_report"  "fq.gz"  

# here's how you can add SLURM options and arguments to the command above to receive an email when the job is done
#sbatch --mail-user=jdoe@odu.edu --mail-type=END /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh "fq_raw" "fqc_raw_report"  "fq.gz"  

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

You can use the command `squeue -u <YourUserName>` to make sure that your job is running on a compute node


<details><summary>Errors?</summary>
<p>
	
If you get a message about not finding `crun` then load the following containers in your current session and run `Multi_FASTQC.sh` again.

```bash
enable_lmod
module load parallel
module load container_env multiqc
module load container_env fastqc

# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh "fq_raw" "fqc_raw_report"  "fq.gz"
	
# check to see that your job is running
watch squeue -u <YourUserName>
```
	
---
	
</p>
</details>


Review the `MultiQC` output (`fq_raw/fastqc_report.html`). You can push your changes to github, then copy and paste the url to the raw html on github into this site: https://htmlpreview.github.io/ .  Note that because our repo is private, there is a token attached to the link that goes stale pretty quickly. 

Make notes in your <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>/README.md file as follows:

	Potential issues:  
	  * % duplication - 
		* Alb: XX%, Contemp: XX%
	  * GC content - 
		* Alb: XX%, Contemp: XX%
	  * number of reads - 
		* Alb: XX mil, Contemp: XX mil


### If you run `Multi_FASTQC.sh` multiple times...

you may generate multiple directories of metadata. However, we have now set `Multiqc_FASTQC.sh` to overwrite existing multiqc reports with the same name.  Please either delete the erroneous dirs or add `_deprecated` to the dir that's created.  Any metadata file with `deprecated` in its path will be ignored by the scripts in the [`process_sequencing_metadata` repo](https://github.com/philippinespire/process_sequencing_metadata), which aggregates sequencing metadata across species.

---

</p>
</details>


<details><summary>8. First trim</summary>
<p>

## **8. First trim.**

Execute [`runFASTP_1st_trim.sbatch`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_1st_trim.sbatch) (0.5-3 hours run time)**

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch runFASTP_1st_trim.sbatch <indir> <outdir>
#do not use trailing / in paths
# note, if your dir is set up correctly, this relative path will work
sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/runFASTP_1st_trim.sbatch fq_raw fq_fp1 

# here's how you can add SLURM options and arguments to the command above to receive an email when the job is done
# replace jdoe@odu.edu with your email address
#sbatch --mail-user=jdoe@odu.edu --mail-type=END /home/e1garcia/pire_fq_gz_processing/runFASTP_1st_trim.sbatch fq_raw fq_fp1 
	
# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

Review the `FastQC` output (`fq_fp1/1st_fastp_report.html`) and update your `README.md`:
```
Potential issues:  
  * % duplication - 
    * Alb: XX%, Contemp: XX%
  * GC content -
    * Alb: XX%, Contemp: XX%
  * passing filter - 
    * Alb: XX%, Contemp: XX%
  * % adapter - 
    * Alb: XX%, Contemp: XX%
  * number of reads - 
    * Alb: XX mil, Contemp: XX mil
```
---

</p>
</details>

<details><summary>9. Remove duplicates with clumpify</summary>
<p>

---

<details><summary>9a. Remove duplicates</summary>
<p>

## **9a. Remove duplicates.**

Execute [`runCLUMPIFY_r1r2_array.bash`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runCLUMPIFY_r1r2_array.bash) (0.5-3 hours run time)**

`runCLUMPIFY_r1r2_array.bash` is a bash script that executes several sbatch jobs to de-duplicate and clumpify your `fq.gz` files. It does two things:

1. Removes duplicate reads.
2. Re-orders each `fq.gz` file so that similar sequences (reads) appear closer together. This helps with file compression and speeds up downstream steps.

You will need to specify the number of nodes you wish to allocate your jobs to. The max # of nodes to use at once should not exceed the number of pairs of r1-r2 files to be processed. (Ex: If you have 3 pairs of r1-r2 files, you should only use 3 nodes at most.) If you have many sets of files (likely to occur if you are processing capture data), you might also limit the nodes to the current number of idle nodes to avoid waiting on the queue (run `sinfo` to find out # of nodes idle in the main partition).

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#runCLUMPIFY_r1r2_array.bash <indir with fp1 files> <outdir> <tempdir> <max # of nodes to use at once>
#do not use trailing / in paths
bash ../../pire_fq_gz_processing/runCLUMPIFY_r1r2_array.bash fq_fp1 fq_fp1_clmp /scratch/<YOURUSERNAME> 20

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

---

</p>
</details>


<details><summary>9b. Addressing memory errors </summary>
<p>

If you check your slurm out and clumpify failed, then it is highly likely that it ran out of memory, temp disk space, or storage disk space.

---

### Addressing Temp Disk Space Issues

To address your temp disk space, use the following command to view the files and dirs in the dir you assigned to be the temp dir (`ls` probably wont work well)

```bash
# wahab
TEMPDIR=/scratch/<YOURUSERNAME>

# turing
TEMPDIR=/scratch-lustre/<YOURUSERNAME>

find $TEMPDIR -name "*"
```

Files can accumulate in your scratch dir if either (1) you put them there on purpose, or (2) clumpify, spades, or some other program errors out before completion.  

If you have a lot of files from clumpify, then you can delete them as follows:

```bash
# wahab
TEMPDIR=/scratch/<YOURUSERNAME>

# turing
TEMPDIR=/scratch-lustre/<YOURUSERNAME>

find $TEMPDIR -name "*clumpify*temp*" -exec rm -rf {} \;
```

If you have a lot of files or dirs from another program, such as spades, then you can delete them as follows by modifying the `-name` pattern, and adjusting the command to apply to the files and dirs. In this case, we add `-rf` to remove dirs:

```bash
# wahab
TEMPDIR=/scratch/<YOURUSERNAME>

# turing
TEMPDIR=/scratch-lustre/<YOURUSERNAME>

find $TEMPDIR -name "*spades*" -exec rm -rf {} \;
```

Repeat as necessary to clean up your scratch drive and try running clumpify again.  

If you keep running out of temp disk space, then you can try decreasing the number of jobs for the slurm array to run at once.  It might be that running 20 jobs at the same time will fill up your temp dir (1TB) before the jobs finish and delete their temp files.  In this example, we change the number of jobs to run simultaneously to 1

```bash
bash ../../pire_fq_gz_processing/runCLUMPIFY_r1r2_array.bash fq_fp1 fq_fp1_clmp /scratch/<YOURUSERNAME> 1
```

Also, everytime clumpify fails, it's a good idea to check for leftover files in the scratch drive and remove them. 

---

### Addressing disk space issues

Contact your PI, and let them know that the disk is full.  Remember, you get a limited allocation of space and we are mainly using the dir of Eric Garcia, which has much more space allotted, but it does fill up from time to time.

---

### Addressing Memory (RAM) Issues

If you are running out of memory (RAM), there can be two ways this presents.  The first is a very quick fail, where java never gets started.  This can be controlled by the amount of memory made available to java in the script. The second way a memory error could present is a delayed fail, where eventually java doesn't have access to enough memory. This happens because you ran out of memory on the node.  Here we introduce an alternate clumpify script which gives more control over parameters affecting ram usage.  If adjusting the settings below doesn't work, try using the turing himem queue

`runCLUMPIFY_r1r2_array2.bash <indir with fp1 files> <outdir> <tempdir> <max # of jobs to run at once> <threads per job> <amount of ram given to each job in java> <name of queue, i.e. the SBATCH -p argument>`

```
# wahab 'main' queue example
# "1" job run at a time, being very conservative here, you might be able to increase
# there are "40" threads on a wahab main node, so each job gets a whole node
# There are 384gb of ram on a wahab main node, so each job is given "233g" of that node

bash ../../pire_fq_gz_processing/runCLUMPIFY_r1r2_array2.bash fq_fp1 fq_fp1_clmp /scratch/<YOURUSERNAME> 1 40 233g main
```

```
# turing 'himem' queue example
# "1" job run at a time, being very conservative here, you might be able to increase
# there are "32" threads on a wahab main node, so each job gets a whole node
# There are 512-7XXgb of ram on a wahab main node, so each job is given "460g" of that node, you might try adjusting this up or down

bash ../../pire_fq_gz_processing/runCLUMPIFY_r1r2_array2.bash fq_fp1 fq_fp1_clmp /scratch-lustre/<YOURUSERNAME> 1 32 460g himem
```

---

</p>
</details>


<details><summary>9c. Check duplicate removal success </summary>
<p>

## **9c. Check duplicate removal success**

After completion, run [`checkClumpify_EG.R`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/checkClumpify_EG.R) to see if any files failed.

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

salloc #because R is interactive and takes a decent amount of memory, we want to grab an interactive node to run this
enable_lmod
module load container_env mapdamage2

crun R < <yourPireDirPath>/pire_fq_gq_processing/checkClumpify_EG.R --no-save
exit #to relinquish the interactive node

#if the previous line returns an error that tidyverse is missing then do the following
crun R

#you are now in the R environment (there should be a > rather than $), install tidyverse
install.packages("tidyverse") #when prompted, type "yes"

#when the install is complete, exit R with the following keystroke combo: ctrl-d (typing q() also works)
#type "n" when asked about saving the environment

#you are now in the shell environment and you should be able to run the checkClumpify script
crun R < checkClumpify_EG.R --no-save
```

If all files were successful, `checkClumpify_EG.R` will return "Clumpify Successfully worked on all samples". 

If some failed, the script will also let you know. Try raising "-c 20" to "-c 40" in the `runCLUMPIFY_r1r2_array.bash` and run Clumplify again.

Also look for this error *"OpenJDK 64-Bit Server VM warning:
INFO: os::commit_memory(0x00007fc08c000000, 204010946560, 0) failed; error='Not enough space' (errno=12)"*

If the array set up doesn't work, try running Clumpify on a Turing himem (high memory) node.

---

</p>
</details>


<details><summary>9d. Clean the Scratch Drive </summary>
<p>

## **9d. Clean the Scratch Drive**

Clumpify gums up your scratch drive with a lot of temporary files.  You must delete them or else you'll run out of space.

`cleanSCRATCH.sbatch <Directory Path> <Pattern>`


```bash
# on wahab
cleanSCRATCH.sbatch /scratch/<YOURUSERNAME> "*clumpify*temp*"
```

```bash
# on turning
cleanSCRATCH.sbatch /scratch-lustre/<YOURUSERNAME> "*clumpify*temp*"
```

---

</p>
</details>


<details><summary>9e. Generate metadata on deduplicated FASTQ files </summary>
<p>

## **9e. Generate metadata on deduplicated FASTQ files**

Once `CLUMPIFY` has finished running and there are no issues, run [`runMULTIQC.sbatch`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runMULTIQC.sbatch) to get the MultiQC output.

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch Multi_FASTQC.sh "<indir>" "<mqc report name>" "<file extension to qc>"
#do not use trailing / in paths. Example:
sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh "fq_fp1_clmp" "fqc_clmp_report"  "fq.gz"

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```



---

</p>
</details>

---

</p>
</details>

<details><summary>10. Second trim</summary>
<p>

## **10. Second trim. Execute `runFASTP_2.sbatch` (0.5-3 hours run time)**

If you are going to assemble a genome with this data, use [runFASTP_2_ssl.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_2_ssl.sbatch). Otherwise, use [runFASTP_2_cssl.sbatch](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFASTP_2_cssl.sbatch).  Modify the script name in the code blocks below as necessary. 

```sh
# move to your species dir
cd /home/e1garcia/shotgun_PIRE/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch runFASTP_2.sbatch <indir> <outdir>
#do not use trailing / in paths

# if lcwgs or cssl run this line
sbatch ../../pire_fq_gz_processing/runFASTP_2.sbatch fq_fp1_clmp fq_fp1_clmp_fp2 33

# otherwise if ssl run this line
sbatch ../../pire_fq_gz_processing/runFASTP_2.sbatch fq_fp1_clmp fq_fp1_clmp_fp2 140

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

Review the results with the `FastQC` output (`fq_fp1_clmp_fp2/2nd_fastp_report.html`) and update your `README.md`.

Potential issues:  
  * % duplication - 
    * Alb: XX%, Contemp: XX%
  * GC content - 
    *  Alb: XX%, Contemp: XX%
  * passing filter - 
    * Alb: XX%, Contemp: XX%
  * % adapter - 
    * Alb: XX%, Contemp: XX%
  * number of reads - 
    * Alb: XX mil, Contemp: XX mil

If you loose too many reads in this step when running the `runFASTP_2.sbatch` script, you can decrease the stringency of the Minimum Sequence Length filter. In this example we set it very low, to 33.

```bash
# remove reads less than 33 bp 
sbatch ../../pire_fq_gz_processing/runFASTP_2.sbatch fq_fp1_clmp fq_fp1_clmp_fp2_33 33
```

To decide on the right cutoff, you could run the following script to generate counts of read lengths in every fq.gz file in a dir.  I would run the most lenient Length filter for the fastp2 trim of 33 first

```bash
# generate read length counts from fp2
bash read_length_counter.bash -n 1000 fq_fp1_clmp_fp2 > fq_fp1_clmp_fp2/read_length_counts.tsv

# generate read length counts from fp2_33
bash read_length_counter.bash -n 1000 fq_fp1_clmp_fp2_33 > fq_fp1_clmp_fp2_33/read_length_counts.tsv

# generate read length counts from fp1
bash read_length_counter.bash -n 1000 fq_fp1_clmp_fp1 > fq_fp1/read_length_counts.tsv

```

Download the read length data and use the following R script in this repo to make histograms `plot_read_length.R`

---

</p>
</details>


<details><summary>11. Decontaminate</summary>
<p>

## **11. Decontaminate files.**

Execute [`runFQSCRN_6.bash`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runFQSCRN_6.bash) (several hours run time)**

`FastQ Screen` works to identify and remove contamination by mapping the reads in our `fq.gz` files to a set of bacterial, protist, virus, fungi, human, etc. genome assemblies that we previously downloaded. If any of the reads in any of the `fq.gz` files map (or "hit") to one or more of these assemblies they are removed from the `fq.gz` file. 

Like with Clumpify, `runFQSCRN_6.bash` is a bash script that executes several sbatch jobs. You will need to specify the number of nodes you wish to allocate your jobs to. Try running 1 node per `fq.gz` file if possible. (Ex: If you have 3 pairs of r1-r2 files, you should only use 6 nodes maximum (1 per file)). If you have many `fq.gz` files (likely to occur if you are processing capture data), you might also limit the nodes to the current number of idle nodes to avoid waiting on the queue (run `sinfo` to find out # of nodes idle in the main partition).
  * ***NOTE: You are executing the bash not the sbatch script.***
  * ***This can take up to several days depending on the size of your dataset. Plan accordingly!***

```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#runFQSCRN_6.bash <indir; fp2 files> <outdir> <number of nodes running simultaneously>
#do not use trailing / in paths
bash ../../pire_fq_gz_processing/runFQSCRN_6.bash fq_fp1_clmp_fp2 fq_fp1_clmp_fp2_fqscrn 20

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

Once done, confirm that all files were successfully completed.

```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#FastQ Screen generates 5 files (*tagged.fastq.gz, *tagged_filter.fastq.gz, *screen.txt, *screen.png, *screen.html) for each input fq.gz file
#check that all 5 files were created for each file: 
ls fq_fp1_clmp_fp2_fqscrn/*tagged.fastq.gz | wc -l
ls fq_fp1_clmp_fp2_fqscrn/*tagged_filter.fastq.gz | wc -l 
ls fq_fp1_clmp_fp2_fqscrn/*screen.txt | wc -l
ls fq_fp1_clmp_fp2_fqscrn/*screen.png | wc -l
ls fq_fp1_clmp_fp2_fqscrn/*screen.html | wc -l

#for each, you should have the same number as the number of input files (number of fq.gz files)

#you should also check for errors in the *out files:
#this will return any out files that had a problem

#do all out files at once
grep 'error' slurm-fqscrn.*out
grep 'No reads in' slurm-fqscrn.*out

#or check individuals files <replace JOBID with your actual job ID>
grep 'error' slurm-fqscrn.JOBID*out
grep 'No reads in' slurm-fqscrn.JOBID*out
```

If you see missing indiviudals or categories in the FastQC output, there was likely a RAM error. The "error" search term may not catch it.

Run the files that failed again.

```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#runFQSCRN_6.bash <indir; fp2 files> <outdir> <number of nodes to run simultaneously> <fq file pattern to process>
#do not use trailing / in paths. Example:
bash ../../pire_fq_gz_processing/runFQSCRN_6.bash fq_fp1_clmp_fp2 fq_fp1_clmp_fp2_fqscrn 1 LlA01010*r1.fq.gz
```

Once `FastQ Screen` has finished running and there are no issues, run [`runMULTIQC.sbatch`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runMULTIQC.sbatch) to get the MultiQC output.

```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch runMULTIQC.sbatch <indir; fqscreen files> <report name>
#do not use trailing / in paths
sbatch ../../pire_fq_gz_processing/runMULTIQC.sbatch fq_fp1_clmp_fp2_fqscrn fastq_screen_report
```

Review the results with the `MultiQC` output (`fq_fp1_clmp_fp2_fqscrn/fastq_screen_report.html`) and update your `README.md`.

Potential issues:

  * one hit, one genome, no ID - 
    * Alb: XX%, Contemp: XX%
  * no one hit, one genome to any potential contaminators (bacteria, virus, human, etc) - 
    * Alb: XX%, Contemp: XX%

---

</p>
</details>


<details><summary>12. Repair FASTQ Files Messed Up by FASTQ_SCREEN</summary>
<p>

## **12. Execute [`runREPAIR.sbatch`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/runREPAIR.sbatch) (<1 hour run time)**

`runREPAIR.sbatch` does not "repair" reads but instead re-pairs them. Basically, it matches up forward (r1) and reverse (r2) reads so that the `*1.fq.gz` and `*2.fq.gz` files have reads in the same order.

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#runREPAIR.sbatch <indir; fqscreen files> <outdir> <threads>
sbatch ../../pire_fq_gz_processing/runREPAIR.sbatch fq_fp1_clmp_fp2_fqscrn fq_fp1_clmp_fp2_fqscrn_rprd 40

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

Once the job has finished, run [`Multi_FASTQC.sh`](https://github.com/philippinespire/pire_fq_gz_processing/blob/main/Multi_FASTQC.sh) separately.

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#sbatch Multi_FASTQC.sh "<indir>" "<output report name>" "<file extension>"
#do not use trailing / in paths. Example:
sbatch /home/e1garcia/shotgun_PIRE/pire_fq_gz_processing/Multi_FASTQC.sh "./fq_fp1_clmp_fp2_fqscrn_rprd" "fqc_rprd_report" "fq.gz"

# check to be sure the job is running
watch squeue -u <YOURUSERNAME>
```

Review the results with the `MultiQC` output (`fq_fp1_clmp_fp2_fqscrn_rprd/fastqc_report.html`) and update your `README.md`.

Potential issues:  
  * % duplication - 
    * Alb: XX%, Contemp: XX%
  * GC content - 
    * Alb: XX%, Contemp: XX%
  * number of reads - 
    * Alb: XX mil, Contemp: XX mil

---

</p>
</details>


<details><summary>13. Calculate the percent of reads lost in each step</summary>
<p>

This is now accomplished in another way using the process_sequencing_metadata repo. Move onto the next step	

<!-- 
	
## **13. Calculate the percent of reads lost in each step**

`read_calculator_ssl.sh` counts the number of reads before and after each step in the pre-process of ssl (or cssl) data and creates the dir `preprocess_read_change` with the following 2 tables:

  1. `readLoss_table.tsv` which reports the step-specific percentage of reads lost and the final cumulative percentage of reads lost.
  2. `readsRemaining_table.tsv` which reports the step-specific percentage of reads that remain and the final cumulative percentage of reads that remain.
 
```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

#read_calculator_ssl.sh "<path to species home dir>" "<Path to dir with raw files>"
#do not use trailing / in paths.

# SSL Example:
sbatch ../../pire_fq_gz_processing/read_calculator.sh "." "fq_raw"

```

Once the job has finished, inspect the two tables and revisit steps if too much data was lost.

Reads lost:

  * fastp1 dropped XX% of the reads
  * XX% of reads were duplicates and were dropped by Clumpify
  * fastp2 dropped XX% of the reads after deduplication
  
Reads remaining:

Total reads remaining: XX%

-->

---

</p>
</details>



<details><summary>14. Clean Up</summary>
<p>

## **14. Clean Up**

Move any `.out` files into the `logs` dir (if you have not already done this as you went along):

```sh
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>

mv *out logs/
```

Be sure to update your `README.md` file so that others know what happened in your directory. Ideally, somebody should be able to replicate what you did exactly.

***Congratulations!!** You have finished the pre-processing steps for your data analysis. Now move on to either the [SSL](https://github.com/philippinespire/pire_ssl_data_processing) or [CSSL](https://github.com/philippinespire/pire_cssl_data_processing) pipelines.*

---

</p>
</details>

<details><summary>15. Map Repaired `fq.gz` to Reference Genome</summary>
<p>

## **15. Map Repaired `fq.gz` to Reference Genome**

Follow specific instructions in CSSL or LCWGS `README.md`.  Does not apply to SSL

---

</p>
</details>


<details><summary>16. Filter RAW BAM Files</summary>
<p>

## **16. Filter BAM Files**

Follow specific instructions in CSSL or LCWGS `README.md`.  Does not apply to SSL

---

</p>
</details>


<details><summary>17. Generate Number of Mapped Reads</summary>
<p>

## **17. Generate Number of Mapped Reads**

This is for CSSL or LCWGS libraries, not SSL. 

```bash
# on wahab replace <yourPireDirPath> with /home/e1garcia/shotgun_PIRE
cd <yourPireDirPath>/pire_<ssl-or-cssl-or-lcwgs>_data_processing/<genus_species>
# sbatch mappedReadStats.sbatch "-RG.bam"
sbatch ../../pire_fq_gz_processing/mappedReadStats.sbatch mkBAM mkBAM/coverageMappedReads 
```

---

</p>
</details>
