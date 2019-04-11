#!/bin/bash
# first argument: full path to directory to crawl, e.g. ~/astor/defect4j_tests/math70
# second argument: full path to astor main directory, e.g. ~/astor/

resultsDir=$2results
modes=(jmutrepair jkali jgenprog)
scopes=(local package global)
seedValue=10
treshold=0.1
maxTime=100
#local path to your junit executable
junitPath="./examples/libs/junit-4.4.jar"
#abosulte path to the jre 7, used for defect4j
jvmPath="/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin"
tests=$(ls $1)

date=$(date '+%d-%m-%Y-%H-%M-%S');
runSummary=$resultsDir"/summary-"$date".txt"

echo -e "[INFO] start run at $date" |& tee "$runSummary"
#create results dir if necessary
if [ ! -d $resultsDir ]; then
	mkdir $resultsDir $resultsDir/success
	echo -e "[INFO] created $resultsDir to store results" |& tee -a "$runSummary"
fi

#build astor
echo -e "[\e[35mBUILD\e[39m] astor in $2" |& tee -a "$runSummary"
cd $2
mvn clean compile

# iterate over all tests given in the directory
for currenttest in $tests; do
	fullPath=$1$currenttest/

	echo -e "\e[32m\n* * * * * * * * New * * * * * * * *"
	echo -e "[\e[39mFILE\e[39m] $fullPath \n"
	
	#compile and current build test case
	cd $fullPath
	mvn clean compile test |& tee "$resultsDir/$currenttest-build-output.txt"
	cd $2
	mvn dependency:build-classpath -B | egrep -v "(^\[INFO\]|^\[WARNING\])" | tee /tmp/astor-classpath.txt
	
	# iterate over all of the three modes
	for mode in ${modes[@]}; do
		
		# iterate over all of the three scopes
		for scope in ${scopes[@]}; do	
			runname="$currenttest-$mode-$scope"
			outputFile="$resultsDir/$runname.txt"
			successString="Found Solution"
			summaryString="----SUMMARY_EXECUTION---"
			
			# check if this test was already run with the current configuration
			if  [ ! -f "$outputFile" ] || ! grep -q "[DONE]" "$outputFile" ; then
				echo -e "[\e[35mRUN\e[39m] $runname" |& tee -a "$runSummary"
			
				java -cp $(cat /tmp/astor-classpath.txt):target/classes fr.inria.main.evolution.AstorMain -jvm4testexecution $jvmPath -mode $mode -scope $scope -srcjavafolder /src/java/ -srctestfolder /src/test/ -binjavafolder /target/classes/ -bintestfolder /target/test-classes/ -location $fullPath -dependencies $junitPath -flthreshold $treshold -maxtime $maxTime -stopfirst true |& tee "$outputFile"
				echo "[DONE]" >> "$outputFile"
				echo -e "[\e[32mDONE\e[39m]: $runname is finished!" |& tee -a "$runSummary"
			else
				echo -e "[\e[33mSKIP\e[39m]: $runname was already done!" |& tee -a "$runSummary"
			fi	

			if  [ -f "$outputFile" ] && grep -q "$successString" "$outputFile" ; then
				echo -e "[\e[32mSUCCESS\e[39m]: $runname found a fix in $runTime seconds!" |& tee -a "$runSummary"=
				awk '/$summaryString/,0' "$outputFile" |& tee -a "$runSummary"
			elif [ -f "$outputFile" ] && grep -q "Exception" "$outputFile" ; then				
				echo -e "[\e[31m[EXCEPTION\e[39m]: $runname had an exception: $exceptionInfo" |& tee -a "$runSummary"
				awk '/Exception/,0' "$outputFile" |& tee -a "$runSummary"
			elif [ -f "$outputFile" ] && grep -q "$summaryString" "$outputFile" ; then
				echo -e "[\e[33m[WARNING\e[39m]: $runname did not find a fix in $runTime seconds!" |& tee -a "$runSummary"
				awk '/$summaryString/,0' "$outputFile" |& tee -a "$runSummary"	 		
			else 
				echo -e "[\e[31mFAILURE\e[39m]: $runname did not finish properly!" |& tee -a "$runSummary"
			fi
			
			echo -e "\n" |& tee -a "$runSummary"
		done	
	done
    echo -e "- - - - - - - - END - - - - - - - -\n"
done
