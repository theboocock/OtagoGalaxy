#!/bin/sh

DIR=$HOME/snpEff/
DIR_SNPSIFT=$HOME/snpEff/snpSiftBin/
LIB=$HOME/snpEff/lib
LIB_SNPSIFT=$HOME/snpEff/snpSiftLib/

# Old library reference:
#	-classpath "$LIB/charts4j-1.2.jar:$LIB/flanagan.jar:$LIB/freemarker.jar:$LIB/junit.jar:$LIB/trove-3.0.2.jar:$LIB/akka-actor-2.0-M4.jar:$LIB/scala-library.jar:$DIR:$DIR_SNPSIFT" \

java -Xmx1G \
	-classpath "$LIB/charts4j-1.2.jar:$LIB/freemarker.jar:$LIB/junit.jar:$LIB/trove-3.0.2.jar:$LIB/akka-actor-2.0-M4.jar:$LIB/scala-library.jar:$LIB_SNPSIFT/antlr-3.4-complete.jar:$DIR:$DIR_SNPSIFT" \
	ca.mcgill.mcb.pcingola.vcfEtc.SnpSift \
	$*

