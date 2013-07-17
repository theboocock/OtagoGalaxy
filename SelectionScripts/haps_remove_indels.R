args<-commandArgs(TRUE)
#read in haps file from shapeit
hapsPop=read.table(file=args[1])
hapsPop=hapsPop[nchar(as.character(hapsPop[,4]))==1 & nchar(as.character(hapsPop[,5]))==1, ] #remove indels
write.table(hapsPop, file=paste(args1,".mod",sep=""))