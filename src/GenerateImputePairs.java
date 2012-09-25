public class GenerateImputePairs {

    public static void main(String[] args) {

        int start = Integer.parseInt(args[0]);
        int end = Integer.parseInt(args[1]);

        double pos1 = start;

        while((pos1 + 1.5) <= end) {

            System.out.print(pos1);
            System.out.println(" " + (pos1 + 1.5));
            pos1+=1.5;

        }
        System.out.print(pos1);
        System.out.println(" " + (pos1 + 1.5));
    }

}
