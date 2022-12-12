#!/bin/bash

TEST_CASE_DIR=/opt/occlum/gvisor_syscall_tests
BLOCKLIST_DIR=../blocklist
NGO_BLOCKLIST_DIR=../ngo_blocklist
FILTER=""
NGO_FILTER=""
PROJECT=""
REPEAT=1
GREEN="\033[1;32m"
RED="\033[1;31m"
NO_COLOR="\033[0m"
ECHO="/bin/echo -e"
ERR_MSG="${RED}The parameter is wrong, you can try './single_test.sh -p occlum -s udp_bind_test -t UdpBindTest/SendtoTest.Sendto/0 -r 5'${NO_COLOR}"

get_blocklist() {
    if [[ $PROJECT == "ngo" ]]; then
        if [ -e $NGO_BLOCKLIST_DIR/$SUITE ]; then
            NGO_FILTER=$(cat $NGO_BLOCKLIST_DIR/$SUITE | tr '\n' ':')
        else
            NGO_FILTER=""
        fi
    fi

    # always get occlum filter
    if [ -e $BLOCKLIST_DIR/$SUITE ]; then
        OCCLUM_FILTER=$(cat $BLOCKLIST_DIR/$SUITE | tr '\n' ':')
    else
        OCCLUM_FILTER=""
    fi
    FILTER=$NGO_FILTER$OCCLUM_FILTER
}

run_testcase(){
    if [ -z "$SUITE" ];then
        $ECHO "test suite name must be provided with '-s' option"
        $ECHO $ERR_MSG
        exit -1
    fi

    if [ -f $TEST_CASE_DIR/$SUITE ]; then
        cp $TEST_CASE_DIR/$SUITE ./image/bin
        occlum build -f
    else
        $ECHO "${RED}The test suite does not exist${NO_COLOR}"
        exit -1
    fi

    if [ -n "$TESTCASE" ]; then
        # run these test cases
        test_filter=$TESTCASE
    else
        # filter these test cases
        get_blocklist
        test_filter=-$FILTER
    fi

    occlum start

    for i in $(seq 1 $REPEAT); do
        occlum exec /bin/$SUITE --gtest_filter=$test_filter
        if [ $? -ne 0 ]; then
            $ECHO "${RED}Test failed${NO_COLOR}"
            occlum stop
            exit -1
        fi
    done

    occlum stop
}

if [ $# -eq 0 ] ;then
    $ECHO $ERR_MSG
    exit -1
fi
rm -rf occlum_workspace
occlum new occlum_workspace
pushd occlum_workspace

until [ $# -eq 0 ]
do
    case "$1" in
        -p)
            shift 1
            PROJECT=$1
            if [[ $PROJECT = "ngo" ]] || [[ $PROJECT = "occlum" ]];then
                shift 1
                continue
            else
                $ECHO $ERR_MSG
                exit -1
            fi
            ;;
        -s)
            if [ -z $PROJECT ];then
                $ECHO $ERR_MSG
                exit -1
            fi
            shift 1
            SUITE=$1
            shift 1;;
        -t)
            if [ -z $SUITE ];then
                $ECHO $ERR_MSG
                exit -1
            fi
            shift 1
            TESTCASE=$1
            shift 1;;
        -r)
            # SUITE must be provided, TESTCASE is optional
            if [ -z $SUITE ];then
                $ECHO $ERR_MSG
                exit -1
            fi
            shift 1
            REPEAT=$1
            shift 1;;
        *)
            $ECHO $ERR_MSG
            exit -1;;
    esac
done

if [[ $PROJECT = "ngo" ]]; then
    yq '.resource_limits.user_space_size = "800MB" |
        .resource_limits.kernel_space_heap_size = "100MB" |
        .process.default_stack_size = "32MB"' -i Occlum.yaml
else
    new_json="$(jq '.resource_limits.user_space_size = "800MB" |
            .resource_limits.kernel_space_heap_size = "100MB" |
            .process.default_stack_size = "32MB"' Occlum.json)" && \
    echo "${new_json}" > Occlum.json
fi

run_testcase
$ECHO "${GREEN}Test is finished${NO_COLOR}"
