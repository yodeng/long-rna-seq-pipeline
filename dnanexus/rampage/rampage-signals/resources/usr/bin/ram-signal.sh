#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage v1: ram-signal.sh <bam_file> <chrom_sizes>"
    echo "Converts BAMs from rampage alignments to signal files: *._rampage_5p.bw. Is independent of DX and encodeD."
    exit -1; 
fi
bam_file=$1      # Bam file.
chrom_sizes=$2   # chrom_sizes file that matches the genome used to create bam_root.

bam_root=${bam_file%.bam}
signal_root=${bam_root}_rampage_5p

echo "-- Signal files will be: '${signal_root}_*.bw'"

echo "-- Make signals..."
set -x
mkdir -p Signal
STAR --runMode inputAlignmentsFromBAM --inputBAMfile $bam_file --outWigType bedGraph read1_5p \
     --outWigStrand Stranded --outFileNamePrefix read1_5p. --outWigReferencesPrefix chr
set +x

echo "-- Convert bedGraph to bigWigs..."
set -x
bedGraphToBigWig read1_5p.Signal.UniqueMultiple.str2.out.bg $chrom_sizes ${signal_root}_minusAll.bw
bedGraphToBigWig read1_5p.Signal.Unique.str2.out.bg         $chrom_sizes ${signal_root}_minusUniq.bw
bedGraphToBigWig read1_5p.Signal.UniqueMultiple.str1.out.bg $chrom_sizes ${signal_root}_plusAll.bw
bedGraphToBigWig read1_5p.Signal.Unique.str1.out.bg         $chrom_sizes ${signal_root}_plusUniq.bw
set +x

echo "-- The results..."
ls -l ${signal_root}_*.bw
