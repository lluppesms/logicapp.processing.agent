# Set up GitHub Actions

The GitHub workflows in this project require several secrets set at the repository level or at the environment level.

---

## Workflow Definitions

- **[1-bicep-only.yml](./workflows/1-bicep-only.yml):** Deploys the main.bicep template with all new resources and does nothing else
- **[3-build-deploy-app.yml](./workflows/3-build-deploy-app.yml):** Builds the app and deploys it to Azure - this should happen automatically after each check-in to main
- **[4-bicep-build-deploy-app.yml](./workflows/4-bicep-build-deploy-app.yml):** Builds the app and deploys it to Azure - this should happen automatically after each check-in to main
- **[5-smoke-test.yml](./workflows/5-smoke-test.yml):** Runs a Playwright smoke test of the application
- **[6-scan-build-pr.yml](./workflows/6-scan-build-pr.yml):** Runs a build up every pull request to ensure the code builds and passes all tests
- **[7-scan-devsecops.yml](./workflows/7-scan-devsecops.yml):** Runs a security scan on the application and infrastructure code.
- **[8-scan-codeql.yml](./workflows/8-scan-codeql.yml):** Runs a scheduled CodeQL scan of the app for application review

---

## Credentials and Secrets

Review the [CreateGitHubSecrets.md](./CreateGitHubSecrets.md) to set up the required secrets and variables for these workflows to run.

---

[Home Page](../README.md)
