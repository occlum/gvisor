#!/bin/bash

set -x

TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests

for syscall_test in $TEST_BIN_DIR/*
do
    $syscall_test
done
