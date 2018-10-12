#!/usr/bin/env bash

set -euo pipefail

test_iterations=${1}
tarball=${2}
test_suite=${3}
jepsen_args=()

function init_jepsen_args {
	jepsen_args=(--ha-storage-dir hdfs:///flink
	--job-jar bin/DataStreamAllroundTestProgram.jar
	--job-args "--environment.parallelism ${1} --state_backend.checkpoint_directory hdfs:///checkpoints --state_backend rocks --state_backend.rocks.incremental true"
	--nodes-file ~/nodes
	--tarball ${tarball}
	--username admin
	--ssh-private-key ~/.ssh/id_rsa)
}

function run_yarn_session_tests {
	init_jepsen_args 10
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers --deployment-mode yarn-session
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --deployment-mode yarn-session
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery --deployment-mode yarn-session
}

function run_yarn_job_tests {
	init_jepsen_args 10
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers --deployment-mode yarn-job
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --deployment-mode yarn-job
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery --deployment-mode yarn-job
}

function run_yarn_job_kill_tm_tests {
	init_jepsen_args 10
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-single-task-manager --deployment-mode yarn-job
}

function run_mesos_session_tests {
	init_jepsen_args 10
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-task-managers --deployment-mode mesos-session
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --deployment-mode mesos-session
	lein run test "${jepsen_args[@]}" --nemesis-gen fail-name-node-during-recovery --deployment-mode mesos-session
}

function run_standalone_session_tests {
	init_jepsen_args 3
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --deployment-mode standalone-session
	lein run test "${jepsen_args[@]}" --nemesis-gen kill-job-managers --client-gen cancel-job --deployment-mode standalone-session
}

for i in $(seq 1 ${1})
do
	echo "Executing run #${i} of ${test_iterations}"
	case ${test_suite} in
		yarn-session)
			run_yarn_session_tests
			;;
		yarn-job)
			run_yarn_job_tests
			;;
		yarn-job-kill-tm)
			run_yarn_job_kill_tm_tests
			;;
		mesos-session)
			run_mesos_session_tests
			;;
		standalone-session)
			run_standalone_session_tests
			;;
		all)
			run_yarn_session_tests
			run_yarn_job_tests
			run_yarn_job_kill_tm_tests
			run_mesos_session_tests
			run_standalone_session_tests
			;;
		*)
			echo "Unknown test suite: ${test_suite}"
			exit 1
			;;
	esac
	echo
done
