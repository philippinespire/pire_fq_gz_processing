#!/bin/bash -l

#SBATCH --job-name=Samtools
#SBATCH -o mappedReadStats_-%j.out
#SBATCH --time=00:00:00
#SBATCH --cpus-per-task=32

enable_lmod
module load container_env samtools
#module load parallel

export SINGULARITY_BIND="/home/cbird,/home/e1garcia/"

BAMPATH=$(echo $1 | sed "s/\/$//")
OUTDIR=$2
#SPECIES=$3

if [[ -z "$3" ]]; then
        BAMPATTERN="-RG.bam"
else
        BAMPATTERN=$3
fi

mkdir -p $OUTDIR

avgBP () {
        BAMFILE=$1
        crun.samtools samtools view $BAMFILE | \
                cut -f10 | \
                awk '{ print length }' | \
                awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'
}
export -f avgBP

avgDP () {
        # return mean depth for positions with coverage
        BAMFILE=$1
        crun.samtools samtools depth -s $BAMFILE | \
                cut -f3 | \
                awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'
}
export -f avgDP

posWWOCVG () {
        # return num pos with and without coverage
        # 3 cols
        # num_pos num_pos_w_cvg
        BAMFILE=$1
        crun.samtools samtools coverage $BAMFILE | \
                cut -f3,5 | \
                awk 'BEGIN { OFS = "\t" } {for (i=1;i<=NF;i++) a[i]+=$i} END{for (i=1;i<=NF;i++) printf a[i] OFS; printf "\n"}'
}
export -f posWWOCVG

#meanNumReadPerSeq () {
#       # mean number of reads per sequence
#       BAMFILE=$1
#       samtools view $BAMFILE | \
#       cut -f1 | \
#       head -n 100000 | \
#       sort | \
#       uniq -c | \
#       tr -s " " "\t" | \
#       cut -f2 |
#       awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }'
#}
#export -f meanNumReadPerSeq

ls $BAMPATH/*$BAMPATTERN | \
        parallel --no-notice -j 20 "echo {} && crun.samtools samtools view -c {} && avgBP {} && avgDP {} && posWWOCVG {}" | \
        paste - - - - - | \
        awk 'BEGIN { OFS = "\t" } NR>=1 {$7 = $4 * $6 / $5} 1' | \
        awk 'BEGIN { OFS = "\t" } NR>=1 {$8 = 100 * $6 / $5} 1' > $OUTDIR/out_${SPECIES}_ReadStats.tsv
# output
# filename numreads meanreadlength meandepth_wcvg numpos numpos_wcvg meandepth pctpos_wcvg

# Adding a header
sed -i '1s/^/filename\tnumreads\tmeanreadlength\tmeandepth_wcvg\tnumpos\tnumpos_wcvg\tmeandepth\tpctpos_wcvg\n/' $OUTDIR/out_${SPECIES}_ReadStats.tsv
echo `date`
echo $BAMPATH
echo $OUTDIR
#echo $SPECIES
echo $BAMPATTERN
echo $(ls $BAMPATH/*$BAMPATTERN)
