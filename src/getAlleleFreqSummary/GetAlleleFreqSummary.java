/**
 *
 * This converts a VCF containing Allele Frequency information 
 * and returns a user chosen delimitted file containing only column 
 * headings containing 'AF'.
 *
 * @Author James Boocock and Edward Hills
 * @Date 27/01/2012 - Updated 30/01/2012
 *
 **/

import java.util.Scanner;
import java.util.ArrayList;
import java.io.*;
import java.util.regex.*;

public class GetAlleleFreqSummary{
	
	private static ArrayList<String> infoColumnA;
	private static int offSet;
    private static final String DELIMITTER = "\t";

	public static void main(String[] args){
		if(args.length < 1 || args[0].equals("-h")){
			usage();
			System.exit(1);
		}
		try {
		Scanner fileReader=new Scanner(new File(args[0]));
		printKey();
        buildColumnHeaders(fileReader);
        System.out.println();
		extractLine(fileReader);
		} catch(FileNotFoundException e){
		e.printStackTrace();
		System.exit(1);
		
		}
	}

    public static void printKey() {
        
        System.out.println("************* KEY *************************\n");
        System.out.println("LDAF \t = \t Linkage Disequilibrium Allele Frequency");
        System.out.println("AF \t = \t Allele Frequency");
        System.out.println("AMR_AF \t = \t American AF");
        System.out.println("ASN_AF \t = \t Asian AF");
        System.out.println("AFR_AF \t = \t African AF");
        System.out.println("EUR_AF \t = \t European AF");
        System.out.println("*******************************************\n");

    }

	public static void usage(){
		System.out.println("Program: Returns Allele Frequency formatted output\n");
		System.out.println("Usage: java GetAlleleFreqSummary <IN.vcf>");
	}

	public static void extractLine(Scanner input){
		String row="";
		while(input.hasNextLine()){
			row ="";
			String line=input.nextLine();
			Scanner tokens=new Scanner(line);
			String[] listInfo=new String[infoColumnA.size()];
			for(int i = 0; i < listInfo.length; i++){
				listInfo[i] = "";
			}
			int x = 0;
			while(x < 7){
				x++;
				row += tokens.next() + DELIMITTER;
			}
			if(tokens.hasNext()){	
				String data=tokens.next();
				String[] info = data.split(";");
				for(int i = 0; i < info.length; i++){
					String indValue= info[i];
					String[] bothParts = indValue.split("=");
					if(infoColumnA.contains(bothParts[0])){
						int headerIndex = infoColumnA.indexOf(bothParts[0]);
						if(bothParts[0].matches("^.*AF.*")){
							listInfo[headerIndex] = bothParts[1];						
						}
					
					}						
				}
				for(int i = 0; i < listInfo.length; i ++){
					row+= listInfo[i] + DELIMITTER;	
				}
			}
			while(tokens.hasNext()){
				row+= tokens.next() + DELIMITTER;
			}
			System.out.println(row);
		}
	}

	public static void buildColumnHeaders(Scanner input){
		String infoColumn="";
		infoColumnA = new ArrayList<String>();
		int lineCount=0;
		while(input.hasNextLine()){
			String line=input.nextLine();
			if (line.matches("^##INFO.*")){
					String columnName="";
					int i = 11;
					while(line.charAt(i) != ','){
						columnName += line.charAt(i);	
						i++;
						}
					if(columnName.matches("^.*AF.*")){
					infoColumnA.add(columnName);
					}
				}
			if (line.matches("^#CHROM.*")){
				Scanner headerScan= new Scanner(line);
				int countC = 0;
				while(headerScan.hasNext()){
					String columnName=headerScan.next();
					if(countC == 0){
						columnName = columnName.substring(1);
					}
					if(columnName.matches("INFO")){
						offSet=countC;
						for(String temp: infoColumnA){
							infoColumn += temp + DELIMITTER;
						}
					}else{
						infoColumn += columnName + DELIMITTER;
					}
					countC++;	
					
				}
			System.out.println(infoColumn);
			return;
			}
			lineCount++;
		}
	}

}
