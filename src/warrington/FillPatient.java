/**
* 
* @File FillPatient.java
* @Date 10/12/12
* @Author Edward Hills
* @Company Otago University
*/

import java.io.*;
import java.util.Scanner;
import java.util.TreeMap;
import java.util.Arrays;

/* 
* FillPatient will scan through the input file and will check to see if
* all patients that are provided in the patient list given are present.
* If a patient is missing then it will be added with no values in the
* allele column.
*/
public class FillPatient {

    public static int[] patients = new int[10000];
    public static TreeMap<Integer, String> block = new TreeMap<Integer, String>();

    /**
    * main method will open the input file and patient list file and 
    * check if every patient in the patient list is present in the
    * input file.
    * @param args0 input file
    * @param args1 patient list
    */
    public static void main (String[] args) {
        try {
        File inputFile = new File(args[0]);
        File patientList = new File(args[1]);
        
        Scanner inputFileScanner = new Scanner(inputFile);
        Scanner lineGrabber = new Scanner(inputFile);
        Scanner patientFileScanner = new Scanner(patientList);
        
	inputFileScanner.nextLine();
	lineGrabber.nextLine();

        // fill the patient list
        int count = 0;
        while (patientFileScanner.hasNextLine()) {
            patients[count++] = Integer.parseInt(patientFileScanner.nextLine());
        }
        Arrays.sort(patients);
       
        String prev_rsid = "";
        String curr_rsid = "";
        String line = "";
        int patientid;
        count = 1;
        while (inputFileScanner.hasNextLine()) {
            patientid = Integer.parseInt(inputFileScanner.next());
            curr_rsid = inputFileScanner.next();
            inputFileScanner.nextLine();
            line = lineGrabber.nextLine();
            
            if (!(curr_rsid.equals(prev_rsid)) && count != 1) {
                compareAndAdd(prev_rsid);
                count = 1;
                block.clear();
            }
            
            if (count == 1 || curr_rsid.equals(prev_rsid)) {
                block.put(patientid, line);
            }

            prev_rsid = curr_rsid;
            count++;
        }
       
        compareAndAdd(prev_rsid);
        
        } catch (IOException e) {
            System.err.println("cannot open files " + args[0] + " " + args[1]);
        }

    }

    /*
    * compareAndAdd will check if the patient that is currently being read in
    * is in the patientlist and if it is not then that patientid will be 
    * printed with the rsid next to it.
    * @param rs rsid
    */
    public static void compareAndAdd(String rs) {
        for (int i = 0; i < patients.length; i++) {
            if (patients[i] != 0) {
        
                if (block.containsKey(patients[i])) {
                   System.out.println(block.get(patients[i]));
                } else {
                    System.out.println(patients[i] + "\t" + rs);
                }
            }
        }
            
    }

} // end class
