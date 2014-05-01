import os,re,vcf

from optparse import OptionParser

# 
# vcf_to_haplogrep 
# used on mtDNA data in VCF format.
# especially the 1kg and merriman sequences data.
# 
#
#


def vcf_to_haplogrep(vcf_input,hgrep_output):
    vcf_reader = vcf.Reader(open(vcf_input,'r'),strict_whitespace=True)
    hgrep_o = open(hgrep_output,'w')
    hgrep_o.write('SampleId\tRange\tHaploGroup\tPolymorphisms (delimited by tab)\n')
    samples = vcf_reader.samples
    sample_lines = {}
    min_max_coord = []
    first_coordinate =True
    for sample in samples:
        sample_lines[sample] = []
    for record in vcf_reader:
        position=record.POS
        if(first_coordinate):
            min_max_coord.append(str(position))
            first_coordinate=False
        alt=record.ALT
        no_alleles = 1 + len(alt)
        ref=record.REF
        for sample in record.samples:
            #print(sample['GT'])
            genotype=sample['GT']
            if(genotype == None): continue
            s = sample.sample
            # Check whether we have something different from the
            # reference.
            #print(position)
            genotype = genotype.split('/')[0]
            if(int(genotype) != 0):
                real_gt=str(alt[int(genotype)-1])
                temp_position=position
                for i in range(0,max(len(real_gt),len(ref))):
                    if ( i == (len(real_gt) - 1) and i == (len(ref)- 1)):              
                        gt = real_gt[i]
                        sample_lines[s].append(str(position+i) + gt)
                    elif(len(real_gt) > len(ref) and i != 0):
                        gt = real_gt[i]
                        sample_lines[s].append(str(temp_position+i-1) + "."  + str(i) + gt)  
                        temp_position = temp_position - 1 
                         
                    elif(len(real_gt) < len(ref) and i != 0):
                        sample_lines[s].append(str(position+i) + "d" )
    min_max_coord.append(str(position))                   
    for sample, substitions in sample_lines.items():
        output_line = []
        output_line.append(sample)
        output_line.append('-'.join(min_max_coord))
        output_line.append("?")
        for sub in substitions:
            output_line.append(sub)
        #print(output_line) 
        output_line = "\t".join(output_line) + "\n"
        #print(output_line)
        hgrep_o.write(output_line)
          

def main():
    parser = OptionParser()
    parser.add_option('-i','--vcf',dest="vcf_input",help="VCF input file")
    parser.add_option('-o','--output',dest="vcf_output",help="Output haplogrep file")
    (options,args) = parser.parse_args()
    vcf_to_haplogrep(options.vcf_input,options.vcf_output)



if __name__=="__main__":main()
