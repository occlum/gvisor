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
- Run passed tests on ngo, run
```
./run_occlum_passed_tests.sh ngo
```

You can use `./run_test_case.sh` to run one or more test cases,this script supports two required parameters '-w' '-s', and one optional parameter '-t' as shown below.
```
	usage: run_test_case.sh [options]

	
	options:
   	-w occlum/ngo     Execute test cases that pass in occlum or test cases that pass in ngo
	-s testcase	  Execute the testcase entered by the user
	-t subtest	  Execute only user-entered subtests in this test suite

	eg: 
	If you want to run udp_bind_test to pass the status in occlum, run
		./run_test_case.sh -w occlum -s udp_bind_test

	If you want to run udp_bind_test to pass the status in ngo, run
		./run_test_case.sh -w ngo -s udp_bind_test
	
	If you want to run "UdpBindTest/SendtoTest.Sendto/0" in udp_bind_test separately, run
		./run_test_case.sh -w occlum -s udp_bind_test -t UdpBindTest/SendtoTest.Sendto/0
```

To add a test that are passed in occlum, put the name to `occlum_test_list.txt`. Sometimes, not all the subtests in a test can be passed. Add the failed subtests to the file in foler `blocklist`. Then, the failed subtests will not be run.
