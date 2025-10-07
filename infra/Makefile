SHELL := /bin/bash
TF_DIR ?= infra/terraform/envs/$(ENV)
ENV ?= dev

.PHONY: fmt validate plan apply destroy bootstrap init

fmt:
terraform -chdir=$(TF_DIR) fmt -recursive

validate: init
terraform -chdir=$(TF_DIR) validate

plan: init
terraform -chdir=$(TF_DIR) plan

apply: init
terraform -chdir=$(TF_DIR) apply -auto-approve

destroy: init
terraform -chdir=$(TF_DIR) destroy -auto-approve

init:
terraform -chdir=$(TF_DIR) init

bootstrap:
terraform -chdir=infra/terraform/global/backend init
terraform -chdir=infra/terraform/global/backend apply -auto-approve
