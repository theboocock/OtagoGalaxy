/**
 *
 * This converts VCF to a human readable format ready to be imported
 * into excel or a similar spreadsheet program.
 *
 *
 * @Author James Boocock
 * @date 23/01/2012
 *
 **/

import java.util.Scanner;
import java.util.ArrayList;
import java.io.*;
import java.util.regex.*;


public class VcfToCsv{
	
	private static ArrayList<String> infoColumnA;
	private static int offSet;

	public static void main(String[] args){
		if(args.length < 1 || args[0].equals("-h")){
			usage();
			System.exit(1);
		}
		try {
		Scanner fileReader=new Scanner(new File(args[0]));
		buildColumnHeaders(fileReader);
		extractLine(fileReader);
		} catch(FileNotFoundException e){
		e.printStackTrace();
		System.exit(1);
		
		}
	}

	public static void usage(){
		System.out.println("program: VCF to CSV converter\n");
		System.out.println("Usage: java VcfToCsv <IN.vcf>");
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
				row += "\""+ tokens.next()+"\"" +",";
			}
			if(tokens.hasNext()){	
				String data=tokens.next();
				String[] info = data.split(";");
				for(int i = 0; i < info.length; i++){
					String indValue= info[i];
					String[] bothParts = indValue.split("=");
					if(infoColumnA.contains(bothParts[0])){
						int headerIndex = infoColumnA.indexOf(bothParts[0]);
						if(bothParts[0].compareTo("INDEL")==0){
							listInfo[infoColumnA.indexOf("INDEL")] = "Y";							
						}else {
                            if (bothParts.length > 1){
						        listInfo[headerIndex]= bothParts[1];
						    }else{
                                listInfo[headerIndex] ="NA";
                            }
					    }						
				    }
                }
				for(int i = 0; i < listInfo.length; i ++){
					row+= "\"" + listInfo[i]+"\"" + ",";	
				}
			}
			while(tokens.hasNext()){
				row+= "\"" + tokens.next() + "\"" + ",";
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
					infoColumnA.add(columnName);
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
							infoColumn+=temp+",";
						}
						// put info column splice here
					}else{
						infoColumn+=columnName+",";
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
