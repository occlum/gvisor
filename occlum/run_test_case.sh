#!/bin/bash
TEST_CASE_DIR=/opt/occlum/gvisor_syscall_tests
BLOCKLIST_DIR=../blocklist
NGO_BLOCKLIST_DIR=../ngo_blocklist
FILTER=""
NGO_FILTER=""
VERSION=""
TESTCASE_NUMBER=0

get_blocklist_subtests(){
        if [ -f $BLOCKLIST_DIR/$testcase ]; then
                FILTER=$(cat $BLOCKLIST_DIR/$testcase | tr '\n' ':')
        else
                FILTER=""
        fi
}

get_ngo_blocklist_subtests(){
	if [ -f $NGO_BLOCKLIST_DIR/$testcase ]; then
		NGO_FILTER=$(cat $NGO_BLOCKLIST_DIR/$testcase | tr '\n' ':')
	else
		NGO_FILTER=""
	fi
}

run_testcase(){
	if [ -e /$TEST_CASE_DIR/$testcase ];then
		cp $TEST_CASE_DIR/$testcase ./image/bin
                occlum build
		if [ -z $subtest ];then 
			if [[ $VERSION = "ngo" ]];then
				get_blocklist_subtests $testcase
				get_ngo_blocklist_subtests $testcase
			elif [[ $VERSION = "occlum" ]];then
				get_blocklist_subtests $testcase
			fi
			FILTER=$FILTER$NGO_FILTER
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

if [ $# -eq 0 ] ;then
	echo "Missing parameters, you can try './run_test_case.sh -w occlum -s udp_bind_test -t UdpBindTest/SendtoTest.Sendto/0' "
	exit -1
fi
rm -rf occlum_workspace
occlum new occlum_workspace
pushd occlum_workspace
until [ $# -eq 0 ]
do
	case "$1" in
		-s)
			if [ -z $VERSION ];then
				echo "Missing arguments, you can use '-w occlum' to run test cases that pass in occlum or '-w ngo' to run test cases that pass in ngo"
				exit -1
			fi
			shift 1
			TESTCASE_NUMBER=`expr $TESTCASE_NUMBER + 1`
			if [ `expr $TESTCASE_NUMBER % 2` -eq 0 ];then
				run_testcase 
			fi
			testcase=$1
			shift 1;;
		-t) 	
			if [ -z $testcase ];then
				echo "Please add '-w' to specify the running version and '-s' to specify the test suite to run this time"
				exit -1
			fi	
			shift 1
			subtest=$1
			run_testcase 
			TESTCASE_NUMBER=0
			testcase=""
			subtest=""
			shift 1;;
		-w)
			shift 1
			VERSION=$1
			if [[ $VERSION = "ngo" ]] || [[ $VERSION = "occlum" ]];then
				shift 1
				continue
			else
				echo "The parameter is wrong, you can use '-w occlum' to run the test cases that passed in occlum or '-w ngo' to run the test cases that passed in ngo"	
				exit -1
			fi
			;;
		*)
			echo "The parameter is wrong, you can try './run_test_case.sh -w occlum -s udp_bind_test -t UdpBindTest/SendtoTest.Sendto/0'"
			exit -1;;
	esac
done

if [ -z $testcase ];then
        exit -1
else
        run_testcase 
fi
