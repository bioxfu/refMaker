# install softwares
conda create -n gatk gatk picard samtools bedtools
source activate gatk
gatk3-register GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar.bz2

# download rice genome
mkdir genome
cd genome
wget -c http://rapdb.dna.affrc.go.jp/download/archive/irgsp1/IRGSP-1.0_genome.fasta.gz
gunzip IRGSP-1.0_genome.fasta.gz
cd ..

# convert to new reference with VCF file
OLD_REF=IRGSP-1.0
NEW_REF=Kinamaze
VCF=Kin-I_combined.flt.vcf

samtools faidx genome/${OLD_REF}_genome.fasta
picard CreateSequenceDictionary R=./genome/${OLD_REF}_genome.fasta O=./genome/${OLD_REF}_genome.dict
gatk3 -T FastaAlternateReferenceMaker -R ./genome/${OLD_REF}_genome.fasta -V ${VCF} -o ./genome/${NEW_REF}_genome.fa
# keep the ID same with original fasta
cat ./genome/${NEW_REF}_genome.fa|sed -r 's/^>.+? />/'|sed 's/:1//' > tmp; mv tmp ./genome/${NEW_REF}_genome.fa

# double check
# manually select some SNPs which are located between the 5' end of the chromosome and the first INDEL
TEST_VCF=SNP_for_test.vcf
bedtools getfasta -fi genome/${OLD_REF}_genome.fasta -bed $TEST_VCF -fo SNP_ref.fa
bedtools getfasta -fi genome/${NEW_REF}_genome.fa -bed $TEST_VCF -fo SNP_alt.fa

paste SNP_ref.fa SNP_alt.fa|grep -v '>'|awk '{print toupper($0)}' > SNP_ref_alt_fa
cat $TEST_VCF|cut -f4,5|awk '{print toupper($0)}' > SNP_ref_alt_vcf
diff SNP_ref_alt_fa SNP_ref_alt_vcf
