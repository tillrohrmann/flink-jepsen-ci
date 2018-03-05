# jepsen.flink automation tools

This project is a collection of configuration files to run the jepsen.flink
test suite on a real cluster deployed on AWS EC2 instances.

## Usage

This repository is set up to allow you to run the Jepsen tests as part of a CI system, or interactively for local development/testing.

In both scenarios the Makefile is the method of performing these operations and should always be consulted first.

### Dependencies

The following dependencies are required to run these tests:

 - Access to an AWS account (being able to assume a role with policy `PowerUserAccess` or `AdministratorAccess` is probably easiest)
 - [Ansible](https://github.com/ansible/ansible)
 - [Boto](https://github.com/boto/boto)
 - [Make](https://www.gnu.org/software/make/)
 - [Terraform](https://github.com/hashicorp/terraform)

We don't prescribe how you assume access to the role for the AWS account, so this leaves you a lot of options.

 - [Boto instructions for credentials](http://boto.cloudhackers.com/en/latest/boto_config_tut.html#credentials)
 - [AWS Environment Variables documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html)

But it's important to know that because Boto2 is being used by the [dynamic inventory](https://github.com/ansible/ansible/blob/devel/contrib/inventory/ec2.py#L162) in Ansible, it _does not_ support assuming a role for you via the `AWS_PROFILE` environment variable like Ansible, Terraform, Boto3, and the AWS CLI support. You'll instead have to assume the role yourself manually or using a helper tool like [remind101/assume-role](https://github.com/remind101/assume-role), and exporting the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, and `AWS_SECURITY_TOKEN` variables into your environment (well that's one way we'd suggest at least).

### Manual/interactive usage

1. Set things up first by issuing `make setup`

1. Then apply the terraform configuration using `make apply`

1. Now run ansible on the new instances with `make ansible`

1. Then if you're finished you can destroy the nodes `make destroy`

1. Finally you can do a `make cleanup` if you like; removes the log/output files

### CI usage

Assuming that the dependencies have been taken care of already.

To run everything in a CI setup, simply run `make run` and it will do everything for you.

This includes retrieving a log of the output of the Ansible task in `run-tests.log` and the direct Jepsen output in a folder called `store` which contains a hierarchy of output pertaining to the various steps of the tests, and the node it was run on etc.
