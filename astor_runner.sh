#!/bin/bash
# first argument: path to directory to crawl, e.g. ~/astor/defect4j_tests/math70

modes=(jmutrepair jkali jgenprog)
scopes=(file package application)
seedValue=10
treshold=0.5
maxTime=100
jvmPath="/usr/lib/jvm/java-1.7.0-openjdk-amd64/bin"

tests=$(ls $1)

# iterate over all tests given in the directory
for currenttest in $tests; do
	echo -e "\e[32m\n\n\n\n* * * * * * * * New * * * * * * * *"
	echo -e "FILE:" $currenttest "\n"
	
	cd $currenttest
	mvn clean compile test |& tee results/$currenttest"-build-output"
	cd ~/astor/
	mvn dependency:build-classpath -B | egrep -v "(^\[INFO\]|^\[WARNING\])" | tee /tmp/astor-classpath.txt
	
	# iterate over all of the three modes
	for mode in ${modes[@]}; do
		
		# iterate over all of the three scopes
		for scope in ${scopes[@]}; do		
			echo -e "\n\n\FILE:\e[34m" $currenttest " run with mode: " $mode " in scope: " $scope "\n"
		
			outputFileName=$currenttest"-"$mode"-"$scope
			java -cp $(cat /tmp/astor-classpath.txt):target/classes fr.inria.main.evolution.AstorMain -scope $scope -jvm4testexecution $jvmPath -mode $mode -srcjavafolder /src/java/ -srctestfolder /src/test/  -binjavafolder /target/classes/ -bintestfolder  /target/test-classes/ -location $currenttest -dependencies ./examples/libs/junit-4.4.jar -flthreshold $treshold -seed $seedValue -maxtime $maxTime -stopfirst true |& tee results/$outputFileName
		done	
	done
	 
    echo -e "- - - - - - - - END - - - - - - - -\n"
done
