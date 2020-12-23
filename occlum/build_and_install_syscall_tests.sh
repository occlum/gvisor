#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TEST_BIN_DIR=/opt/occlum/gvisor_syscall_tests

set -e

cd ../
bazel build --test_tag_filters=native //test/syscalls/...

mkdir -p $TEST_BIN_DIR
cp bazel-bin/test/syscalls/linux/*_test $TEST_BIN_DIR

rm -rf bazel-gvisor

echo "All the test binaries are installed into $TEST_BIN_DIR"
