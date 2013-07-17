

import sys
import os

#$1 haps file to split
#$2 final line `tail -1 <haps file>
#$3 first line `head -1 <haps file>
#$4 Size of split files <window size>
#$5 overlap = 100000
# Remove final file

def main():
	final_line = sys.argv[2]
	first_line = sys.argv[3]
	print(first_line)
	firstCoord = int(first_line.split()[2])
	lastCoord = int(final_line.split()[2])
	window = int(sys.argv[4])
	overlap = int(sys.argv[5])
	diff = lastCoord 
	print(diff/window)
	
	first_file = open(sys.argv[1].split('.')[0]+str(1) + '.phaps','w')
	for i in range(1,int(diff/window)+1):
		overlapping_file = open(sys.argv[1].split('.')[0] +str(i+1) + '.phaps','w')
		with open(sys.argv[1],'r') as f:
			for line in f:
				# Ignore offset because it doesnt matetr
				if(int(line.split()[2]) < (window * i) and int(line.split()[2]) >= (window * (i - 1))):
					first_file.write(line)
					
				elif(int(line.split()[2]) >= (window * i)):
					break

				if(int(line.split()[2]) >= ((window * i) - overlap)):
					overlapping_file.write(line)
					#print(overlap)
					
					#print((window * i)-overlap)
		first_file.close()
		first_file =overlapping_file 
	
	with open(sys.argv[1],'r') as f:
		for line in f:
			if(int(line.split()[2]) < (window * diff/window)):
				first_file.write(line)
	first_file.close()
	print("Done Success")


if __name__=="__main__":main()

