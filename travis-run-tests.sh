#!/usr/bin/env bash

# Get test sources and build Flink job
git clone --depth 50 https://github.com/apache/flink.git
cd flink/flink-end-to-end-tests/flink-datastream-allround-test
mvn ${MAVEN_COMPILE_OPTIONS} clean install -DskipTests -Dfast
cp target/DataStreamAllroundTestProgram.jar ../../flink-jepsen/bin/
cd ../../../

# Run tests
while sleep 9m; do echo "Still running ($SECONDS seconds)"; done &
make run EXTRA_VARS="flink_url=\"https://s3.eu-central-1.amazonaws.com/flink-dists-204087123/flink-${TRAVIS_BUILD_NUMBER}.tgz\" test_suite=${TEST_SUITE}"
#make run EXTRA_VARS="test_suite=${TEST_SUITE}"
testrc=$?
kill %1

# Upload test results
test_results_file=store-${TRAVIS_JOB_NUMBER}-${TEST_SUITE}.tgz
tar -czf ${test_results_file} store/
eval $(assume-role testing)
aws s3 cp ${test_results_file} s3://flink-jepsen-test-results --acl public-read
echo "Test artifacts are uploaded to https://s3.eu-central-1.amazonaws.com/flink-jepsen-test-results/${test_results_file}"
exit $testrc
