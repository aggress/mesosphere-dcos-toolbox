
BUILDDIR = "roles/setup/tasks/output"

.PHONY: addup addown help

help:
	@echo ""
	@echo "Please use \`make <target>' where <target> is one of"
	@echo ""
	@echo "  clean                  to remove existing build artifacts"
	@echo "  ad-deploy              to deploy an Active Directory server on AWS"
	@echo "  ad-facts               to get the public DNS name and Administrator password for the AD server on AWS"
	@echo "  ad-destroy             to destroy the AWS Active Directory server"
	@echo "  ======================="
	@echo "  setup-beta-cp-zk       to setup Beta Confluent Platform Zookeeper"
	@echo "  setup-cp-zk            to setup GA Confluent Platform Zookeeper"
	@echo "  setup-beta-cp-kafka    to setup Beta Confluent Platform Kafka"
	@echo "  setup-cp-kafka         to setup GA Confluent Platform Zookeeper"
	@echo "  setup-cp-connect       to setup Confluent Connect"
	@echo "  setup-cp-rest-proxy    to setup Confluent Rest Proxy"
	@echo "  setup-cp-schema        to setup Confluent Schema Registry"
	@echo "  setup-cp-control       to setup Confluent Control Center"
	@echo "  setup-cp-replicator    to setup Confluent Replicator"
	@echo "  ======================="
	@echo "  deploy-beta-cp-zk      to deploy Beta Confluent Platform Zookeeper"
	@echo "  deploy-cp-zk           to deploy GA Confluent Platform Zookeeper"
	@echo "  deploy-beta-cp-kafka   to deploy Beta Confluent Platform Kafka"
	@echo "  deploy-cp-kafka        to deploy GA Confluent Platform Zookeeper"
	@echo "  deploy-cp-connect      to deploy Confluent Connect"
	@echo "  deploy-cp-rest-proxy   to deploy Confluent Rest Proxy"
	@echo "  deploy-cp-schema       to deploy Confluent Schema Registry"
	@echo "  deploy-cp-control      to deploy Confluent Control Center"
	@echo "  deploy-cp-replicator   to deploy Confluent Replicator"
	@echo ""


clean:
	rm -rf $(BUILDDIR)/*

ad-deploy:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=deploy"

ad-facts:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=facts"

ad-destroy:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=destroy"

setup-beta-cp-zk:
	ansible-playbook -i hosts setup.yaml -e "package_to_install=beta-confluent-kafka-zookeeper"

deploy-beta-cp-zk:
	ansible-playbook -i hosts deploy.yaml -e "package_to_install=beta-confluent-kafka-zookeeper"

setup-beta-cp-kafka:
	ansible-playbook -i hosts setup.yaml -e "package_to_install=beta-confluent-kafka"

deploy-beta-cp-kafka:
	ansible-playbook -i hosts deploy.yaml -e "package_to_install=beta-confluent-kafka"