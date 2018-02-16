adup:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=deploy"

addown:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=destroy"

adfacts:
	ansible-playbook -i hosts roles/deploy/tasks/ad_cloudformation_stack.yaml -e "ad_action=facts"

setup_bzk:
	ansible-playbook -i hosts setup.yaml -e "package_to_install=beta-confluent-kafka-zookeeper"

deploy_bzk:
	ansible-playbook -i hosts deploy.yaml -e "package_to_install=beta-confluent-kafka-zookeeper"