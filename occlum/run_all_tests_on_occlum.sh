#!/bin/bash

set -x

TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests
TEST_LIST=occlum_test_list.txt
TESTS=0
PASSED_TESTS=0
RED='\033[0;31m'
NC='\033[0m'
RESULT=0

run_one_test() {
    ret=""

    if [ -f $TEST_BIN_DIR/$1 ]; then
        occlum new occlum_workspace
        pushd occlum_workspace
        cp $TEST_BIN_DIR/$1 image/bin

        occlum build
        occlum run /bin/$1
        ret=$?
        popd
        rm -rf occlum_workspace
    else
        echo "Warning: test does not exist"
        ret=1
    fi

    return $ret
}

for syscall_test in $TEST_BIN_DIR/*
do
    $syscall_test
    [ $? -eq 0 ] && PASSED_TESTS=$((PASSED_TESTS+1))
    TESTS=$((TESTS+1))
done

printf "$RED$PASSED_TESTS$NC of $RED$TESTS$NC test suites are passed\n"

[ $PASSED_TESTS -ne $TESTS ] && RESULT=1
exit $RESULT
