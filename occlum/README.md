# Run gVisor syscall tests on Occlum

- To build the syscall tests, run
```
./build_and_install_syscall_tests.sh
```
The test binaries will be output to `/opt/occlum/gvisor_syscall_tests`.

- To directly run the tests on host, run 
```
./run_all_tests_on_host.sh
```

- To directly run the tests on occlum, run 
```
./run_all_tests_on_occlum.sh
```
Since not all the tests are passed in occlum, failure may be encountered.

- Run passed tests on occlum, run
```
./run_occlum_passed_tests.sh
```
In the cases that have passed, because the version update may encounter some cases of failure, the following script is provided to retest the test cases.
- This script provides a required optional parameter -s [testcase] and an optional parameter -t [subtest], for example: if you only run UdpBindTest/SendtoTest.Sendto/11 in udp_bind_test, you can run
```
./run_one_test_on_occlum.sh -s udp_bind_test -t UdpBindTest/SendtoTest.Sendto/11
```

To add a test that are passed in occlum, put the name to `occlum_test_list.txt`. Sometimes, not all the subtests in a test can be passed. Add the failed subtests to the file in foler `blocklist`. Then, the failed subtests will not be run.
