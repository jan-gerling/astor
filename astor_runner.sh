#!/bin/bash
# first argument: full path to directory to crawl, e.g. ~/astor/defect4j_tests/math70
# second argument: full path to astor main directory, e.g. ~/astor/

resultsDir=$2results
modes=(jmutrepair jkali jgenprog)
scopes=(local package global)
seedValue=10
treshold=0.5
maxTime=100
#local path to your junit executable
junitPath="./examples/libs/junit-4.4.jar"
#abosulte path to the jre 7, used for defect4j
jvmPath="/usr/lib/jvm/java-1.7.0-openjdk-amd64/bin"
tests=$(ls $1)

#create results dir if necessary
if [ ! -d $resultsDir ]; then
	mkdir $resultsDir
	echo -e "[INFO] created $resultsDir to store results"
fi

#build astor
echo -e "\n\n\e[35m [BUILD] astor in $1 \e[39m\n"
cd $1
mvn clean compile

# iterate over all tests given in the directory
for currenttest in $tests; do
	fullPath=$1$currenttest/

	echo -e "\e[32m\n\n\n\n* * * * * * * * New * * * * * * * *"
	echo -e "\e[39mFILE:" $fullPath "\n"
	
	#compile and current build test case
	cd $fullPath
	mvn clean compile test |& tee $resultsDir$currenttest"-build-output.txt"
	cd $2
	mvn dependency:build-classpath -B | egrep -v "(^\[INFO\]|^\[WARNING\])" | tee /tmp/astor-classpath.txt
	
	# iterate over all of the three modes
	for mode in ${modes[@]}; do
		
		# iterate over all of the three scopes
		for scope in ${scopes[@]}; do	
			runname=$currenttest"-"$mode"-"$scope
			outputFile=$resultsDir"/"$runname".txt"
			# check if this test was already run with the current configuration
			if  [ ! -f "$outputFile" ] || [ grep -Fxq "[SUCCESS] for $runname" "$outputFile"]; then
				echo -e "\n\n\e[35m [RUN] $runname \e[39m\n"
			
				java -cp $(cat /tmp/astor-classpath.txt):target/classes fr.inria.main.evolution.AstorMain -jvm4testexecution $jvmPath -mode $mode -scope $scope -srcjavafolder /src/java/ -srctestfolder /src/test/ -binjavafolder /target/classes/ -bintestfolder /target/test-classes/ -location $fullPath -dependencies $junitPath -flthreshold $treshold -seed $seedValue -maxtime $maxTime -stopfirst true |& tee outputFile
				echo "\n \e[42m[SUCCESS] for $runname \e[39m" |& tee outputFile
			else
				echo -e "\n\n\e[33m[WARNING]: $runname was already done! \e[39m\n"
			fi
		done	
	done
    echo -e "- - - - - - - - END - - - - - - - -\n"
done
