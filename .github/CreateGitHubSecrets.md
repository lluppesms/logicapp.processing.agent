# Set up GitHub Secrets

The GitHub workflows in this project require several secrets set at the repository level.

---

## Azure Resource Creation Credentials

You need to set up the Azure Credentials secret in the GitHub Secrets at the Repository level before you do anything else.

See [https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions) for more info.

To create these secrets, customize and run this command::

``` bash
gh auth login

gh secret set AZURE_CLIENT_ID -b <GUID>
gh secret set AZURE_TENANT_ID -b <GUID>
gh secret set AZURE_SUBSCRIPTION_ID -b <yourAzureSubscriptionId>
```

---

## Bicep Configuration Values

These variables and secrets are used by the Bicep templates to configure the resource names that are deployed.  Make sure the App_Name variable is unique to your deploy. It will be used as the basis for the website name and for all the other Azure resources, which must be globally unique.
To create these additional secrets and variables, customize and run this command:

Secret Values:

``` bash
gh auth login

gh variable set APP_NAME -b XXX-lapagent
gh variable set RESOURCE_GROUP_LOCATION -b eastus
gh variable set RESOURCE_GROUP_PREFIX -b rg_lapagent-web

gh variable set INTAKE_PROJECT_FOLDER_NAME -b src/intake-function
gh variable set INTAKE_PROJECT_NAME -b Processor.Agent.Intake
gh variable set INTAKE_TEST_FOLDER_NAME -b src/intake-function-tests
gh variable set INTAKE_TEST_PROJECT_NAME -b Processor.Agent.Intake.Tests

gh variable set ACCEPTOR_PROJECT_FOLDER_NAME -b src/acceptor-logicapp
gh variable set ACCEPTOR_PROJECT_NAME -b Processor.Agent.Acceptor
gh variable set ACCEPTOR_TEST_FOLDER_NAME -b src/acceptor-logicapp-tests
gh variable set ACCEPTOR_TEST_PROJECT_NAME -b Processor.Agent.Acceptor.Tests

```

Optional Values that can be set:

``` bash
gh variable set PRINCIPALID -b xxx
gh variable set MYIPADDRESS -b xxx

gh variable set OPENAI_ENDPOINT -b xxx
gh variable set OPENAI_APIKEY -b xxx
gh variable set OPENAI_DEPLOYMENTNAME -b gpt-5-mini
gh variable set OPENAI_MODELNAME -b gpt_5_mini
gh variable set OPENAI_TEMPERATURE -b 0.8

gh variable set EXISTING_SERVICEPLAN_NAME -b xxx
gh variable set EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME -b xxx
```

---

## References

[Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)

[GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
