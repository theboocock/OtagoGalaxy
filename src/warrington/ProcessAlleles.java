/**
 * @File: ProcessAlleles.java
 * @Date: 18/11/11
 * @Authors: Edward Hills and James Boocock
 *
 * @Description: This file proccess the alleles. It calculates a value
 *               either 0, 1 or 2 depending on what is the major, minor
 *               allele. 1 will always be the heterozygous allele and 0
 *               the major allele.
 */

import java.util.Scanner;
import java.io.*;

/**
 * Process Alleles process the alleles for each SNP, finds out what is the
 * major and minor alleles and appends them onto the input data.
 */
public class ProcessAlleles {

    private static int aFrequency, gFrequency, tFrequency, cFrequency;
    private static int numberOfSubjects;
    private static int aVal, gVal, cVal, tVal;
    private static BufferedWriter outputStream;
    private static boolean toDelete = false;
    private static boolean randomSelect = false;

    /**
     * Reads from file specified from command line, process the allele
     * information and writes the allele information as well as removes
     * deletes from the input file.
     * @param args - String array containing input file, block size,
     *               whether to remove deletes or not and whether to
     *               take the selection randomly or not.
     */
    public static void main(String[] args) {
        if(args[0].equals("-h") || args[0].equals("-help")){
            usage();
        }
        try {
            File file = new File(args[0]);
            outputStream = 
                new BufferedWriter(new FileWriter("~tmp.tmp"));
            if (args[1].equals("no-dels")) {
                toDelete = true;
            }
            if (args[2].equals("random")) {
                randomSelect = true;
            }

            numberOfSubjects = Integer.parseInt(args[3]);

            Scanner input = new Scanner(file);
            Scanner fileReader = new Scanner(file);
            String line;
            int count = 0;
            while (fileReader.hasNextLine()) { //process allele frequency
                getAlleleFreq(input);
                printBlock(fileReader);

                aFrequency=0;
                tFrequency=0;
                cFrequency=0;
                gFrequency=0;
            }
            outputStream.close();
        } catch (IOException e) {
            System.err.println("Unable to write to file");
        }
    }

    /**
     * Prints how to use this program
     */
    public static void usage(){
        System.out.println("Usage: java ProcessAlleles <inputfile> <no-dels> <random-selection> <num-subjects>");
        System.exit(1);
    }

    /**
     * Prints the block of data that has just been processed and appends
     * the allele values onto the input string.
     * @param block - The scanner to process the block of lines.
     */
    public static void printBlock(Scanner block) {
        for (int i = 0; i < numberOfSubjects; i++) {
            String line = block.nextLine();
            try {
                int val = getAlleleVal(line);
                if (toDelete) {
                    if (val != -1) {
                        outputStream.write(line + "\t" + val + "\n");
                    }
                } else {
                    if (val == -1) {
                        outputStream.write(line+"\t" + val + "\n");
                    } else {
                        outputStream.write(line + "\t" + val + "\n");
                    }
                }
            } catch (IOException e) {
                System.err.println("Sorry cannot write to file");
            }
        }

    }

    /** 
     * Returns the allele value based on which is the major allele and minor
     * allele.
     * @param line - The line that is read in containing the data.
     * @return alleleVal - the value of the allele.
     */
    public static int getAlleleVal(String line) {
        Scanner scan = new Scanner(line);
        scan.next();
        scan.next();
        if(scan.hasNext()){
            String firstAllele = scan.next();
            if (scan.hasNext()) {
                String secondAllele = scan.next();
                if (firstAllele.equals("A")) {
                    if (secondAllele.equals("G")) {
                        return 1;
                    } else if(secondAllele.equals("C")) {
                        return 1;    
                    } else if(secondAllele.equals("T")) {
                        return 1;
                    } else if(secondAllele.equals("A")) {
                        return aVal;
                    }
                }
                if (firstAllele.equals("G")) {
                    if (secondAllele.equals("A")) {
                        return 1;
                    } else if(secondAllele.equals("C")) {
                        return 1;    
                    } else if(secondAllele.equals("T")) {
                        return 1;
                    } else if(secondAllele.equals("G")) {
                        return gVal;
                    }
                }
                if (firstAllele.equals("C")) {
                    if (secondAllele.equals("G")) {
                        return 1;
                    } else if(secondAllele.equals("A")) {
                        return 1;    
                    } else if(secondAllele.equals("T")) {
                        return 1;
                    } else if(secondAllele.equals("C")) {
                        return cVal;
                    }
                }
                if (firstAllele.equals("T")) {
                    if (secondAllele.equals("G")) {
                        return 1;
                    } else if(secondAllele.equals("C")) {
                        return 1;    
                    } else if(secondAllele.equals("A")) {
                        return 1;
                    } else if(secondAllele.equals("T")) {
                        return tVal;
                    }
                }
            }
        }
        return -1;
    }

    /**
     * Searches through a block of SNPs and finds the major and minor alleles.
     * @param input - the Scanner object to process the block of SNPs.
     */
    public static void getAlleleFreq(Scanner input) {
        String firstAllele;
        String secondAllele;
        String line;
        Scanner scan;
        for (int i = 0; i < numberOfSubjects; i++) {
            if (input.hasNextLine()) { 
                line = input.nextLine();
                scan = new Scanner(line);
                scan.next();
                scan.next();
                if (scan.hasNext()) {
                    firstAllele = scan.next();
                    if (firstAllele.equals("A")) {
                        aFrequency++;
                    }
                    else if (firstAllele.equals("C")) {
                        cFrequency++;
                    }
                    else if (firstAllele.equals("G")) {
                        gFrequency++;
                    }
                    else if (firstAllele.equals("T")) {
                        tFrequency++;
                    } else {
                        break;
                    }
                    secondAllele = scan.next();
                    if (secondAllele.equals("A")) {
                        aFrequency++;
                    }
                    else if (secondAllele.equals("C")) {
                        cFrequency++;
                    }
                    else if (secondAllele.equals("G")) {
                        gFrequency++;
                    }
                    else if (secondAllele.equals("T")) {
                        tFrequency++;
                    }
                }
            }
        }
        if (aFrequency > gFrequency && aFrequency > cFrequency && aFrequency > tFrequency) { 
            aVal = 0;
            gVal = 2;
            cVal = 2;
            tVal = 2;
        }
        else if (gFrequency > aFrequency && gFrequency > cFrequency && gFrequency > tFrequency) { 
            gVal = 0;
            aVal = 2;
            cVal = 2;
            tVal = 2;
        }
        else if (cFrequency > gFrequency && cFrequency > aFrequency && cFrequency > tFrequency) { 
            cVal = 0;
            gVal = 2;
            aVal = 2;
            tVal = 2;
        } 
        else if (tFrequency > gFrequency && tFrequency > cFrequency && tFrequency > aFrequency) { 
            tVal = 0;
            gVal = 2;
            cVal = 2;
            aVal = 2;
        } else {
            tVal = -666;
            gVal = -666;
            cVal = -666;
            aVal = -666;
        }
    }
} // end class
