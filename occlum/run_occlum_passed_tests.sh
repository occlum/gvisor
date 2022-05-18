#!/bin/bash

TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests
TEST_LIST=../test_list.txt # Test suite that will be running by default
TEST_BLOCKLIST=../ngo_block_suite_list.txt # Test suite that will not be running for NGO
BLOCKLIST_DIR=../blocklist # Test cases that will not be running for Occlum
NGO_BLOCKLIST_DIR=../ngo_blocklist # Test cases that will not be running for NGO
TESTS=0
PASSED_TESTS=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
RESULT=0
FILTER=""
NGO_FILTER=""
OPERATION_MODE=$*

get_ngo_blocklist_subtests(){
	if [ -f $NGO_BLOCKLIST_DIR/$1 ]; then
		NGO_FILTER=$(cat $NGO_BLOCKLIST_DIR/$1 | tr '\n' ':')
		return 0
	else
		NGO_FILTER=""
		return 1
	fi
}

get_blocklist_subtests(){
	if [ -f $BLOCKLIST_DIR/$1 ]; then
		FILTER=$(cat $BLOCKLIST_DIR/$1 | tr '\n' ':')
		return 0
	else
		FILTER=""
		return 1
	fi
}

run_one_test(){
	ret=""
	if [ -f $TEST_BIN_DIR/$1 ]; then
		printf "$GREEN running $1$NC \n"
		if [[ $OPERATION_MODE = "ngo" ]];then
			get_blocklist_subtests $1
			get_ngo_blocklist_subtests $1
			FILTER=$FILTER$NGO_FILTER
			occlum exec /bin/$1 --gtest_filter=-$FILTER
		else
			get_blocklist_subtests $1
			occlum exec /bin/$1 --gtest_filter=-$FILTER
		fi
		ret=$?
		FILTER=""
	else
		echo "Warning: test does not exit"
		ret=1
	fi
	return $ret
}

if [ -z $OPERATION_MODE ];then
	echo -e "$GREEN Running test cases passed in occlum $NC\n"
elif [ $OPERATION_MODE != "ngo" ];then
	echo -e "parameter is wrong, you can use '"./run_occlum_passed_tests.sh ngo"' to run the tests passed in ngo"
	exit -1
elif [ $OPERATION_MODE = "ngo" ];then
	echo -e "$GREEN Running test cases passed in ngo $NC\n"
fi
rm -rf occlum_workspace
occlum new occlum_workspace
pushd occlum_workspace
new_json="$(jq '.resource_limits.user_space_size = "800MB" |
		.resource_limits.kernel_space_heap_size = "100MB" |
		.process.default_mmap_size = "500MB"' Occlum.json)" && \
echo "${new_json}" > Occlum.json
cp $TEST_BIN_DIR/* ./image/bin
occlum build
occlum start
touch log

while read syscall_test;
do
	if [ `grep -c "$syscall_test" $TEST_BLOCKLIST` -eq 1 ] && [[ $OPERATION_MODE = "ngo" ]];then
		continue
	fi
	run_one_test $syscall_test
	TESTS=$((TESTS+1))

	# Ignore futex_test result due to timer's inaccuracy in Occlum
	if [ $? -ne 0 ] && [[ "$syscall_test" != "futex_test" ]]; then
		echo -e "$syscall_test" >> log
	else
		PASSED_TESTS=$((PASSED_TESTS+1))
	fi
done < $TEST_LIST

occlum stop
printf "$RED$PASSED_TESTS$NC of $RED$TESTS$NC test suites are passed\n"
[ $PASSED_TESTS -ne $TESTS ] && RESULT=1
printf "The $(($TESTS-$PASSED_TESTS)) failed test suites in this run are as follows:\n"
cat log
rm log
popd

exit $RESULT
