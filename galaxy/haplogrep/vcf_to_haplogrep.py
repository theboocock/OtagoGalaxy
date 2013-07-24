import os,re,vcf

from optparse import OptionParser


def vcf_to_haplogrep(vcf_input,hgrep_output):
    vcf_reader = vcf.Reader(open(vcf_input,'r'))
    hgrep_o = open(hgrep_output,'w')
    hgrep_o.write('SampleId\tRange\tHaploGroup\tPolymorphisms (delimited by tab)\n") 
    for record in vcf_reader:
        position=Record.POS
        alt=Record.ALT
        ref=Record.REF
        for samples in record.samples
             

def main():
    parser = OptionParser()
    parser.add_option('-i','--vcf',dest="vcf_input",help="VCF input file")
    parser.add_option('-o','--output',dest="dest_output",help="Output haplogrep file")
    (options,args) = parser.parse_args()
    vcf_to_haplogrep(options.vcf_input,options.vcf_output)





if __name__=="__main__":main()
