import os
import sys
import vcf
from optparse import OptionParser

#
# Get_genotypes_by_sample.py
# used to extract the genotypes for
# each snp in the VCF file. 
#
#

def get_genotype_from_sample(vcf_input,output):
    vcf_reader =vcf.Reader(open(vcf_input,'r'))
    out = open(output,'w')
    samples = vcf_reader.samples
    out.write('chrom\tpos\tid\tref\talt'+'\t' + '\t'.join(samples)+'\n')
    for record in vcf_reader:
        position=str(record.POS)
        chrom=str(record.CHROM)
        alt=[str(o) for o in record.ALT]
        ref=str(record.REF)
        id=str(record.ID)
        line=chrom+'\t'+position+'\t'+id+'\t'+ref+'\t'+','.join(alt)+'\t'
        for sample in record.samples:
            genotypes=sample['GT']
            if(genotypes==None):
                line+='NA\t'
                continue
            alleles=[]
            seperator=''
            if(len(genotypes.split('|'))==2):
                allele=genotypes.split('|')
                seperator='|'
                alleles.append(allele[0])
                alleles.append(allele[1])
            else:
                allele=genotypes.split('/')
                seperator='/'
                alleles.append(allele[0])
                alleles.append(allele[1])
            output_genotype=[]
            for a in alleles:
                if(int(a) == 0):
                    output_genotype.append(ref)
                else:
                    output_genotype.append(alt[int(a)-1])
              
            line+=seperator.join(output_genotype) + '\t'
        out.write(line+'\n')



def main():
    parser = OptionParser()
    parser.add_option('-i','--vcf',dest="vcf_input",help="VCF input file")
    parser.add_option('-o','--output',dest="genotype_out",help="Output Genotype File")
    (options, args) = parser.parse_args()
    get_genotype_from_sample(options.vcf_input,options.genotype_out)




if __name__=="__main__":main()
