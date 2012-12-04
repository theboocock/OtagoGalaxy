import java.util.*;

/* reads from stdin and scans along line from vcf to find AF field then prints lines to stdout
 * that are above/below specified AF
 *
 * Murray 3/12/12
 */




public class AFfilter{
    
public static double thresAF=0.0;
public static boolean filterGT = false;
public static String  chr = "", pos = "";

public static String popln = "AF";


    public static void main(String args[]){
        if( args.length >= 2 ){
            thresAF = Double.parseDouble( args[1] );
            if( args[0].equals("gt") ){
                filterGT = true;
            }
        
            if(args.length == 3){
                   popln = args[3]; 
            }
        }else{
            System.err.println("Run: java AFfilter [lt/gt] af [name of AF field]\nDefault is lt 0.0 AF");
            System.exit(0);
        }
        readLines();
    }

    public static void readLines(){
    Scanner scan = new Scanner( System.in );
    while( scan.hasNextLine() ){
            findInfo( scan.nextLine() );
        }
    }

    public static void findInfo( String line ){
        Scanner infoScan = new Scanner( line );
        infoScan.useDelimiter("\t");
        if( line.contains("#") ){ //skip header
            return;
        }
        chr = infoScan.next(); //chr
        pos = infoScan.next(); //pos
        infoScan.next(); //id
        infoScan.next(); //ref
        infoScan.next(); //alt
        infoScan.next(); //qual
        infoScan.next(); //filter
        findAF( infoScan.next() );
    }

    public static void findAF(String info){
        Scanner afScan = new Scanner( info );
        double testAF = 0.0;
        afScan.useDelimiter(";");    
        afScan.findInLine(popln + "=");
        if( afScan.hasNextDouble() ){
            testAF = afScan.nextDouble();
            if( filterGT == false &&  testAF < thresAF   ){
//                System.out.println("testAF= " + testAF + " filterGT= "+filterGT);
                System.out.println( chr + ":" + pos );
            } else if ( filterGT == true && testAF > thresAF){
//                System.out.println("testAF= " + testAF + " filterGT= "+filterGT);
                System.out.println( chr + ":" + pos );
            }
        }
    }

}
