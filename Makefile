DEFAULT_RUN_ID_GEN = $(shell openssl rand -base64 6 | base64)

.PHONY: ansible
ansible: cleanup ansible-inventory
	ansible-playbook -i inventory --extra-vars=run_id=$(or $(RUN_ID),$(shell cat DEFAULT_RUN_ID)) $(ARGS) playbook.yml

.PHONY: ansible-inventory
ansible-inventory:
	@cat inventory.template \
	| sed -e "s/%%RUN_ID%%/$(or $(RUN_ID),$(shell cat DEFAULT_RUN_ID))/" > inventory/inventory

.PHONY: ansible-with-destroy
ansible-with-destroy:
	$(MAKE) ansible || $(MAKE) destroy

.PHONY: apply
apply:
	terraform apply -auto-approve -var 'run_id=$(or $(RUN_ID),$(shell cat DEFAULT_RUN_ID))' terraform

.PHONY: apply-with-destroy
apply-with-destroy:
	$(MAKE) apply || $(MAKE) destroy

.PHONY: cleanup
cleanup:
	@rm -Rf FAILED store run-tests.log

.PHONY: destroy
destroy:
	terraform destroy -auto-approve -var 'run_id=$(or $(RUN_ID),$(shell cat DEFAULT_RUN_ID))' terraform

.PHONY: exit-status
exit-status:
	@./exit-status.sh

.PHONY: init
init:
	terraform init terraform

.PHONY: run
run: setup init apply-with-destroy ansible-with-destroy destroy exit-status

.PHONY: run-id
run-id:
	@echo "$(or $(RUN_ID),$(DEFAULT_RUN_ID_GEN))" > DEFAULT_RUN_ID

.PHONY: setup
setup: ssh-keygen run-id init

.PHONY: ssh-keygen
ssh-keygen:
	ssh-keygen -b 4096 -C "jepsen" -N '' -f ./id_rsa
