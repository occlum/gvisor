#!/bin/bash
TEST_CASE_DIR=/opt/occlum/gvisor_syscall_tests
BLOCKLIST_DIR=../blocklist
FILTER=""

get_blocklist_subtests(){
        if [ -f $BLOCKLIST_DIR/$testcase ]; then
                FILTER=$(cat $BLOCKLIST_DIR/$testcase | tr '\n' ':')
        else
                FILTER=""
        fi
}

run_testcase(){
	if [ -e /$TEST_CASE_DIR/$testcase ];then
		cp $TEST_CASE_DIR/$testcase ./image/bin
                occlum build
		if [ -z $subtest ];then 
                        get_blocklist_subtests $testcase
			occlum run /bin/$testcase --gtest_filter=-$FILTER
			FILTER=""
		else
			occlum run /bin/$testcase --gtest_filter=$subtest
		fi

	else
		echo "The test suite does not exist"
		exit -1
	fi
}


if [ $# -eq 0 ];then
	echo "Missing parameters, you can try to add -s [test suite] -f [subtest]"
	exit -1
fi

rm -rf occlum_workspace
occlum new occlum_workspace
pushd occlum_workspace
until [ $# -eq 0 ]
do
	case "$1" in
		-s)
			shift 1;
			testcase=$1;
			shift 1;
			case "$1" in
				-t) 	shift 1;
					subtest=$1;
					shift 1;
					run_testcase $testcase $subtest
					testcase="";;
				-s) 	run_testcase $testcase
					testcase=""
					continue;;
				*) 	continue;;
			esac
			;;
		*)
			echo "The parameter is wrong, you can try to add -s [test suite] -f [subtest]"
			exit -1;;
	esac
done

if [ -z $testcase ];then
	exit -1
else
	run_testcase $testcase
fi

