#!/bin/bash -e

if [ $# -lt 6 ] || [ $# -gt 7 ]; then
    echo "usage v1: rampage_align_star.sh <star_index.tgz> <read1.fq.gz> [<read2.fq.gz>] <library_id> <ncpus> <ram_GB> <bam_root>"
    echo "Align paired-end reads with STAR for Rampage.  Is independent of DX and encodeD."
    exit -1;
fi
star_index_tgz=$1  # STAR Index archive.
read1_fq_gz=$2     # gzipped fastq of of paired-end read1.
if [ $# -eq 7 ]; then
    read2_fq_gz=$3     # gzipped fastq of of paired-end read2.
    library_id=$4      # Library identifier which will be added to bam header.
    ncpus=$5           # Number of cpus available.
    ram_GB=$6          # ram memory avaliable for STAR sorting
    bam_root=$7        # root name for output bam (e.g. "alignment" will create "alignment_marked.bam")
elif [ $# -eq 6 ]; then
    read2_fq_gz=""     # single-end has only read1
    library_id=$3
    ncpus=$4
    ram_GB=$5
    bam_root=$6
fi

echo "-- Alignments file will be: '${bam_root}_marked.bam'"

echo "-- Extracting star index archive..."
tar zxvf $star_index_tgz
# unzips into "out/"

echo "-- Set up headers..."
set -x
libraryComment="@CO\tLIBID:${library_id}"
echo -e ${libraryComment} > COfile.txt
cat out/*_bamCommentLines.txt >> COfile.txt
set +x
echo "-- cat COfile.txt --"
cat COfile.txt
echo "--------------------"

echo "-- Map reads..."
set -x
STAR --genomeDir out --readFilesIn $read1_fq_gz $read2_fq_gz                         \
    --readFilesCommand zcat --runThreadN $ncpus --genomeLoad NoSharedMemory           \
    --outFilterMultimapNmax 500 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1        \
    --outFilterMismatchNmax 999 --outFilterMismatchNoverReadLmax 0.04                   \
    --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000              \
    --outSAMheaderCommentFile COfile.txt --outSAMheaderHD @HD VN:1.4 SO:coordinate        \
    --outSAMunmapped Within --outFilterType BySJout --outSAMattributes NH HI AS NM MD      \
    --outFilterScoreMinOverLread 0.85 --outFilterIntronMotifs RemoveNoncanonicalUnannotated \
    --clip5pNbases 6 15 --seedSearchStartLmax 30 --outSAMtype BAM SortedByCoordinate         \
    --limitBAMsortRAM ${ram_GB}000000000
set +x
ls -l Aligned.sortedByCoord.out.bam

echo "-- Marking PCR duplicates..."
set -x
STAR --inputBAMfile Aligned.sortedByCoord.out.bam --bamRemoveDuplicatesType UniqueIdentical \
    --runMode inputAlignmentsFromBAM --bamRemoveDuplicatesMate2basesN 15 \
    --outFileNamePrefix markdup. --limitBAMsortRAM ${ram_GB}000000000

mv markdup.Processed.out.bam ${bam_root}_marked.bam
mv Log.final.out ${bam_root}_Log.final.out
set +x

echo "-- Collect bam flagstats..."
set -x
samtools flagstat ${bam_root}_marked.bam > ${bam_root}_marked_flagstat.txt
set +x

echo "-- The results..."
ls -l ${bam_root}*

