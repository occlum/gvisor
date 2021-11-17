#!/bin/bash

#set -x
TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests
BLOCKLIST_DIR=../blocklist
TEST_LIST=../occlum_test_list.txt
TESTS=0
PASSED_TESTS=0
RED='\033[0;31m'
NC='\033[0m'
RESULT=0
FILTER=""

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
		get_blocklist_subtests $1
		occlum exec /bin/$1 --gtest_filter=-$FILTER
		ret=$?
	else
		echo "Warning: test does not exit"
		ret=1
	fi
	return $ret
}

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
    run_one_test $syscall_test
    if [ $? -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS+1));then
	    TESTS=$((TESTS+1))
    else
	    echo -e "$syscall_test" >> log
	    TESTS=$((TESTS+1))
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
