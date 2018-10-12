#!/usr/bin/env bash

set -euo pipefail

# Get test sources & Flink test job
git clone --depth 50 https://github.com/apache/flink.git
wget -O DataStreamAllroundTestProgram.jar https://s3.eu-central-1.amazonaws.com/flink-dists-204087123/DataStreamAllroundTestProgram-${TRAVIS_BUILD_NUMBER}.jar
mv DataStreamAllroundTestProgram.jar flink/flink-jepsen/bin/

# Run tests
while sleep 9m; do echo "Still running ($SECONDS seconds)"; done &
set +e
make run EXTRA_VARS="flink_url=\"https://s3.eu-central-1.amazonaws.com/flink-dists-204087123/flink-${TRAVIS_BUILD_NUMBER}.tgz\" test_suite=${TEST_SUITE} run_count=${TEST_RUN_COUNT}"
testrc=$?
kill %1
set -e

# Upload test results
test_results_file=store-${TRAVIS_JOB_NUMBER}-${TEST_SUITE}.tgz
tar -czf ${test_results_file} store/
eval $(assume-role testing)
aws s3 cp ${test_results_file} s3://flink-jepsen-test-results --acl public-read
echo "Test artifacts are uploaded to https://s3.eu-central-1.amazonaws.com/flink-jepsen-test-results/${test_results_file}"
exit $testrc
