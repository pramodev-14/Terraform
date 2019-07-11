SHELL = /bin/bash

lambda_apps = monitoring-api

pkg_lambda:
	@echo monitoring control apis lambda zip

	# Remove the node_modules before build
	DIRECTORY="node_modules" ; \
	if [ -d "$$DIRECTORY" ]; \
	then \
		rm -rf node_modules/ ; \
	fi 

	for app in $(lambda_apps); \
	do \
		npm install ; \
		zip -q -r $${app}.zip *.js *.json models includes schemas node_modules ; \
		aws s3 cp $${app}.zip s3://${BUILDS_REPO_BUCKET}/teecontrol/$${app}-latest.zip  ; \
		aws s3 cp $${app}.zip s3://${BUILDS_REPO_BUCKET}/teecontrol/$${app}-${CI_COMMIT_SHA}.zip ; \
	done

tinit: 
	@echo terraform init 
	cd terraform && \
	terraform init 

twnew: 
	@echo terraform workspace new ${CI_ENVIRONMENT_NAME}
	terraform workspace new ${CI_ENVIRONMENT_NAME}

twselect: 
	@echo terraform workspace select ${CI_ENVIRONMENT_NAME}
	terraform workspace select ${CI_ENVIRONMENT_NAME}

tautoapply:
	@echo terraform apply 
	cp -pr monitoring-a*zip terraform/
	cd terraform && \
	terraform apply -input=false -auto-approve -refresh=true -auto-approve -var-file=env/${CI_ENVIRONMENT_NAME}.tfvars -var "build_tag=${CI_COMMIT_SHA}" -var "db_password=$$DB_PASSWORD" -var "lambda_repo_bucket=${DEV_LAMBDA_REPO_BUCKET}"

toutput:
	@echo terraform output 
	cd terraform && \
	terraform output -json > version-control-output.json

init: tinit

plan: tinit tselect 

aapply: init twnew twselect tautoapply toutput 

