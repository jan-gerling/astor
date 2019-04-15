#!/bin/bash
# first argument: full path to directory to crawl, e.g. ~/astor/defect4j_tests/math70
# second argument: full path to astor main directory, e.g. ~/astor/

resultsDir=$2results
modes=(jmutrepair jkali jgenprog)
scopes=(package)
seedValue=10
treshold=0.5
maxTime=100
#local path to your junit executable
junitPath="./examples/libs/junit-4.4.jar"
#abosulte path to the jre 7, used for defect4j
jvmPath="/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin"
tests=$(ls $1)

testTimeMap=(
["time_01"]="org.joda.time.TestPartial_Constructors::testConstructorEx7_TypeArray_intArray"
["time_02"]="org.joda.time.TestPartial_Basics::testWith_baseAndArgHaveNoRange"
["time_03"]="org.joda.time.TestMutableDateTime_Adds::testAddYears_int_dstOverlapWinter_addZero"
["time_04"]="org.joda.time.TestPartial_Basics::testWith3"
["time_05"]="org.joda.time.TestPeriod_Basics::testNormalizedStandard_periodType_months1"
["time_07"]="org.joda.time.format.TestDateTimeFormatter::testParseInto_monthDay_feb29_newYork_startOfYear"
["time_08"]="org.joda.time.TestDateTimeZone::testForOffsetHoursMinutes_int_int"
["time_09"]="org.joda.time.TestDateTimeZone::testForOffsetHoursMinutes_int_int"
["time_10"]="org.joda.time.TestDays::testFactory_daysBetween_RPartial_MonthDay"
["time_11"]="org.joda.time.tz.TestCompiler::testDateTimeZoneBuilder" )


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
mvn clean 
mvn compile

# iterate over all tests given in the directory
for currenttest in $tests; do
	fullPath=$1$currenttest/
	echo -e "\e[32m\n* * * * * * * * New * * * * * * * *"
	echo -e "[\e[34mFILE\e[39m] $fullPath \n"
	
	#compile and current build test case
	buildOutputFile="$resultsDir/$currenttest-build-output.txt"
	testErrorString="Tests in error:"
	testErrorString2="Tests failed:"
	testErrorString3="Failed tests:"
	

	cd $fullPath
	echo -e "[\e[34mCompile\e[39m] Compiling test $currenttest \n"
	mvn clean compile test &> "$buildOutputFile"
	cd $2
	
	#analyze build output
	if  [ -f "$buildOutputFile" ] && grep -q "$testErrorString" "$buildOutputFile"; then
		echo -e "[\e[34mInfo\e[39m]: $currenttest failed to build with test error:" |& tee -a "$runSummary"
		awk '/Tests in error:/,/Tests run:/' "$buildOutputFile" |& tee -a "$runSummary"		
	elif  [ -f "$buildOutputFile" ] && grep -q "$testErrorString2" "$buildOutputFile"; then
		echo -e "[\e[34mInfo\e[39m]: $currenttest failed to build with test error:" |& tee -a "$runSummary"
		awk '/Tests failed:/,/Tests run:/' "$buildOutputFile" |& tee -a "$runSummary"
	elif  [ -f "$buildOutputFile" ] && grep -q "$testErrorString3" "$buildOutputFile"; then
		echo -e "[\e[34mInfo\e[39m]: $currenttest failed to build with test error:" |& tee -a "$runSummary"
		awk '/Failed tests:/,/Tests run:/' "$buildOutputFile" |& tee -a "$runSummary"
	else 
		echo -e "[\e[31mFAILURE\e[39m]: $currenttest was not build properly with a failing test!" |& tee -a "$runSummary"
	fi	
	
	mvn dependency:build-classpath -B | egrep -v "(^\[INFO\]|^\[WARNING\])" &> /tmp/astor-classpath.txt
	
	# iterate over all of the three modes
	for mode in ${modes[@]}; do
		
		# iterate over all of the three scopes
		for scope in ${scopes[@]}; do	
			runname="$currenttest-$mode-$scope"
			outputFile="$resultsDir/$runname.txt"
			successString="Found Solution"
			summaryString="----SUMMARY_EXECUTION---"
			exceptionString="Exception in thread"
			failing="${testTimeMap["$currenttest"]}"
			
			# check if this test was already run with the current configuration
			if  [ ! -f "$outputFile" ] || ! grep -q "[DONE]" "$outputFile" ; then
				echo -e "[\e[34mRUN\e[39m] $runname" |& tee -a "$runSummary"
			
				java -cp $(cat /tmp/astor-classpath.txt):target/classes fr.inria.main.evolution.AstorMain -jvm4testexecution $jvmPath -mode $mode -scope $scope -failing "&failing" -srcjavafolder /src/java/ -srctestfolder /src/test/ -binjavafolder /target/classes/ -bintestfolder /target/test-classes/ -location $fullPath -dependencies $junitPath -flthreshold $treshold -maxtime $maxTime -stopfirst true &> "$outputFile"
				echo "[DONE]" >> "$outputFile"
				echo -e "[\e[34mDONE\e[39m]: $runname is finished!" |& tee -a "$runSummary"
			else
				echo -e "[\e[35mSKIP\e[39m]: $runname was already done!" |& tee -a "$runSummary"
			fi	

			# quickly analyse the output for the summary
			if  [ -f "$outputFile" ] && grep -q "$successString" "$outputFile" ; then
				echo -e "[\e[32mSUCCESS\e[39m]: $runname found a fix!" |& tee -a "$runSummary"
				awk '/$summaryString/,0' "$outputFile" |& tee -a "$runSummary"
			elif [ -f "$outputFile" ] && grep -q "$exceptionString" "$outputFile" ; then				
				echo -e "[\e[31m[EXCEPTION\e[39m]: $runname had an exception: $exceptionInfo" |& tee -a "$runSummary"
				awk '/Exception in thread "main"/,0' "$outputFile" |& tee -a "$runSummary"
			elif [ -f "$outputFile" ] && grep -q "SUMMARY_EXECUTION" "$outputFile" ; then
				echo -e "[\e[33m[WARNING\e[39m]: $runname did not find a fix!" |& tee -a "$runSummary"
				awk '/$summaryString/,0' "$outputFile" |& tee -a "$runSummary"	 		
			else 
				echo -e "[\e[31mFAILURE\e[39m]: $runname did not finish properly!" |& tee -a "$runSummary"
			fi
			
			echo -e "\n" |& tee -a "$runSummary"
		done	
	done
    echo -e "- - - - - - - - END - - - - - - - -\n"
done
