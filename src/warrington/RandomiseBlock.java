/**
* @Author: Ed Hills
* @Date: 2/12/11
* @File: RandomiseBlock.java
*/

import java.io.*;
import java.util.Random;

/**
* This class will generate a random list of unique numbers
*/
public class RandomiseBlock {


    /**
    * Method will read in a given number of lines from the command
    * line and will print that many random whole integers from 0
    * and will -currently- write to a file.
    *
    * @param args[0] - number of psuedo-random numbers to generate
    */
    public static void main(String[] args) {
        try {
            BufferedWriter outputStream = 
                new BufferedWriter(new FileWriter("~tmp.tmp"));

            Random generator = new Random();
            int numLines = Integer.parseInt(args[0]);
            int numLinesToPrint = Integer.parseInt(args[1]);

            boolean[] banList = new boolean[numLines];
            int gennum;
            int cap = 1;
            while (cap <= numLinesToPrint) {    
                gennum = generator.nextInt(numLines);
                if (!banList[gennum]) {
                    outputStream.write("" + gennum + "\n");
                    banList[gennum] = true;
                    cap++;
                }
            }
            outputStream.close();
        } catch (IOException e) {
            System.err.println("Cannot write to file");
        }

    }

} // end class
