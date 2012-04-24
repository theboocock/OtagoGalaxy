#!/bin/sh

DIR=$HOME/snpEff/
LIB=$HOME/snpEff/lib

java -Xmx20G \
	-classpath "$LIB/charts4j-1.2.jar:$LIB/flanagan.jar:$LIB/freemarker.jar:$LIB/junit.jar:$LIB/trove-3.0.2.jar:$LIB/akka-actor-2.0-M4.jar:$LIB/scala-library.jar:$DIR" \
	ca.mcgill.mcb.pcingola.snpEffect.commandLine.SnpEff \
	$*
