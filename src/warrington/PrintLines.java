/* 
* @Author: Ed Hills
* @Date: 2/11/11
* @File: PrintLines.java
**/

import java.util.Scanner;
import java.util.Random;
import java.io.*;

/**
* Class will read through the given input file of SNPs and 
* also in parallel read through the sorted list of numbers 
* which correspons to the line number in the input file and
* will print out each line in the order given by the sorted
* list of numbers.
*/
public class PrintLines {

    /**
    * Method will process two files in parallel and print
    * out each line given by the corresponding file.
    *
    *@param args[0] - the sorted list of numbers
    *       args[1] - the snpsFile
    *       args[2] - number of lines in the snpsFile
    */
    public static void main(String[] args) {
        try {
            File numsFile = new File(args[0]);
            File snpsFile = new File(args[1]);
            boolean[] nums = new boolean[Integer.parseInt(args[2])];
            Scanner scanner = new Scanner(numsFile);
            while (scanner.hasNextLine()) {
                nums[Integer.parseInt(scanner.nextLine())] = true;
            }
            Scanner looper = new Scanner(snpsFile);
            int currLine = 0;
            String line;
            while (looper.hasNextLine()) {
                line = looper.nextLine();
                if (nums[currLine]) {
                    System.out.println(line);
                }
                currLine++;
            }
        } catch (IOException e) {
            System.err.println("cannot read from " + args[0] + " and " + args[1]);
        }

    }

}
