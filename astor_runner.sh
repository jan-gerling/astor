#!/bin/bash
# first argument: full path to directory to crawl, e.g. ~/astor/defect4j_tests/math70
# second argument: full path to astor main directory, e.g. ~/astor/

mkdir $2/results $2/results/done

modes=(jmutrepair jkali jgenprog)
scopes=(File Package Application)
seedValue=10
treshold=0.5
maxTime=100
jvmPath="/usr/lib/jvm/java-1.7.0-openjdk-amd64/bin"

tests=$(ls $1)

# iterate over all tests given in the directory
for currenttest in $tests; do
	fullPath=$1/$currenttest

	echo -e "\e[32m\n\n\n\n* * * * * * * * New * * * * * * * *"
	echo -e "\e[39mFILE:" $fullPath "\n"
	
	#compile and current build test case
	cd $fullPath
	mvn clean compile test |& tee results/$currenttest"-build-output"
	cd $2
	mvn dependency:build-classpath -B | egrep -v "(^\[INFO\]|^\[WARNING\])" | tee /tmp/astor-classpath.txt
	
	# iterate over all of the three modes
	for mode in ${modes[@]}; do
		
		# iterate over all of the three scopes
		for scope in ${scopes[@]}; do		
			echo -e "\n\n\e[35mFILE:" $currenttest " run with mode: " $mode " in scope: " $scope "\n"
			echo -e "java -cp" $(cat /tmp/astor-classpath.txt)":target/classes fr.inria.main.evolution.AstorMain -scope " $scope "-jvm4testexecution" $jvmPath "-mode " $mode "-srcjavafolder /src/java/ -srctestfolder /src/test/ -binjavafolder /target/classes/ -bintestfolder /target/test-classes/ -location "$fullPath "-dependencies ./examples/libs/junit-4.4.jar -flthreshold "$treshold "-seed "$seedValue "-maxtime "$maxTime "-stopfirst true |& tee results/$outputFileName"
			echo -e "\e[39m"
		
			outputFileName=$currenttest"-"$mode"-"$scope
			java -cp $(cat /tmp/astor-classpath.txt):target/classes fr.inria.main.evolution.AstorMain -scope $scope -jvm4testexecution $jvmPath -mode $mode -srcjavafolder /src/java/ -srctestfolder /src/test/ -binjavafolder /target/classes/ -bintestfolder /target/test-classes/ -location $fullPath -dependencies ./examples/libs/junit-4.4.jar -flthreshold $treshold -seed $seedValue -maxtime $maxTime -stopfirst true |& tee results/$outputFileName
		done	
	done
	
	#move completed test cases to other directory
	mv $fullPath $2/results/done
    echo -e "- - - - - - - - END - - - - - - - -\n"
done
