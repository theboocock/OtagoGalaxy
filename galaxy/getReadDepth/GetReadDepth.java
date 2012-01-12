/*
 * @File GetReadDepth.java
 * @Author Edward Hills
 * @Date 12/01/12
 *
 */

import java.util.Scanner;
import java.io.*;

/**
* 
* GetReadDepth scans through the input file given on the command line and
* prints out the first few columns in the file along with the read depth in
* an easy to read and view style.
*
*/
public class GetReadDepth {
    
    /**
    * @param args - The input File given on the command line
    * main method takes in a file as an argument via the command line, reads each line 
    * in the file and calls the getReadDepth() method on the line.
    *
    */
    public static void main(String[] args) {

        if (args.length != 1) {
            System.err.println("You must specify at most 1 input VCF file.");
            System.exit(1);
        }

        try {
            File file = new File(args[0]);
            Scanner input = new Scanner(file);

            System.out.println("Generated from " + args[0] + "\n");
            System.out.println("CHROM\t\tPOS\t\tRSID\t\tREF\t\tALT\t\tREAD_DEPTH\n");
            while (input.hasNextLine()) {
                getReadDepth(input.nextLine());
            }

        } catch (IOException e) {
            System.err.println("Cannot read from " + args[0]);
        }

    }

    /**
    * @param input - the input line to be scanned
    * getReadDepth scans the line given to it, saves a few of the columns and
    * then finds the DP field in the INFO column and prints out the chrom, pos,
    * rsid, alt, ref and finall the read depth columns
    */
    public static void getReadDepth(String input) {
        Scanner line = new Scanner(input);
        String start = line.next();
        if (!(start.substring(0, 1).equals("#"))) {
            String pos = line.next();
            String rsid = line.next();
            String alt = line.next();
            String ref = line.next();
            line.next();
            line.next();
            String info;
            int index;
            String readDepth = "-1";
            if (line.hasNext()) {
                info = line.next();
                index = info.indexOf("DP=");
                if (index != -1) {
                    readDepth = info.substring(index + 3, index + 5);
                    if (readDepth.indexOf(";") > -1) {
                        readDepth = info.substring(index + 3, index + 4);
                    }
                }
            }
            if (! readDepth.equals("-1")) {
                System.out.println(start + "\t\t" + pos + "\t" + rsid + "\t\t" + alt + "\t\t" + ref + "\t\t" + readDepth);
            }
        }

    }

}
