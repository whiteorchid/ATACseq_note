#!/bin/bash

for i in SRR5831513 SRR5831515 SRR5831517  SRR5831519 SRR5831521 SRR5831523 
do

        echo  "#!/bin/bash
#SBATCH --partition=shortterm
#SBATCH --mem=160GB
#SBATCH --mail-user=
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=10
#SBATCH --nodes=1

/work/guo/soft/fastp -i ${i}_1.fastq -I ${i}_2.fastq -o ${i}_1_clean.fastq -O ${i}_2_clean.fastq -h $i


STAR --runThreadN 40 \
--runMode alignReads \
--quantMode  GeneCounts \
--twopassMode Basic \
–outSAMtype BAM SortedByCoordinate \
--outSAMunmapped None \
--genomeDir /data/sb_service_01/guo/ref/ref_star \
--readFilesIn  /work/guo/test/atac/${i}_1_clean.fastq /work/guo/test/atac/${i}_2_clean.fastq \
--outFileNamePrefix $i


samtools view -bS ${i}Aligned.out.sam  -@ 10 | samtools sort - -o ${i}.sorted.bam

samtools index  ${i}.sorted.bam
java -Xmx50g -jar  /opt/picard-tools/2.18.25/picard.jar MarkDuplicates ASSUME_SORTED=true REMOVE_SEQUENCING_DUPLICATES=true \
 INPUT=/work/guo/test/atac/${i}.sorted.bam \
 OUTPUT=/work/guo/test/atac/${i}.sorted.rmdup.bam \
 METRICS_FILE=/work/guo/test/atac/${i}.sorted.rmdup.metrics

export PYTHONPATH=/work/guo/soft/Python-3.11.2/lib/python3.11/site-packages:$PYTHONPATH

export PATH=/work/guo/soft/Python-3.11.2/bin:$PATH

macs3 callpeak -f BAMPE -t ${i}.sorted.rmdup.bam -g hs -n $i -B -q 0.01

" > /work/guo/test/atac/${i}.macs.sh

sbatch /work/guo/test/atac/${i}.macs.sh

done
