init:
	terraform init
plan:
	terraform plan -out new_plan
apply:
	terraform apply new_plan || rm new_plan \
    && rm new_plan
plan-apply:
	terraform plan -out new_plan \
	&& terraform apply new_plan || rm new_plan \
	&& rm new_plan
app-plan-apply:
	terraform plan -out new_plan -target null_resource.stack_deployments \
    terraform apply new_plan || rm new_plan \
    && rm new_plan
