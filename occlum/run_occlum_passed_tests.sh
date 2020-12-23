#!/bin/bash

set -x

TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests
BLOCKLIST_DIR=blocklist/
TEST_LIST=occlum_test_list.txt
TESTS=0
PASSED_TESTS=0
RED='\033[0;31m'
NC='\033[0m'
RESULT=0
FILTER=""

get_blocklisted_subtests() {
	if [ -f $BLOCKLIST_DIR/$1 ]; then
        FILTER=$(cat $BLOCKLIST_DIR/$1 | tr '\n' ':')
        return 0
	else
        FILTER=""
		return 1
    fi
}

run_one_test() {
    ret=""

    if [ -f $TEST_BIN_DIR/$1 ]; then
		get_blocklisted_subtests $1

        occlum new occlum_workspace
        pushd occlum_workspace
        cp $TEST_BIN_DIR/$1 image/bin

        occlum build
        occlum run /bin/$1 --gtest_filter=-$FILTER
        ret=$?
        popd
        rm -rf occlum_workspace
    else
        echo "Warning: test does not exist"
        ret=1
    fi

    return $ret
}



while read syscall_test;
do 
    run_one_test $syscall_test
    [ $? -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS+1))
    TESTS=$((TESTS+1))
done < $TEST_LIST

printf "$RED$PASSED_TESTS$NC of $RED$TESTS$NC test suites are passed\n"

[ $PASSED_TESTS -ne $TESTS ] && RESULT=1
exit $RESULT
