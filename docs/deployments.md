## Deployments

These are the basic instructions for how we're managin deployments.

Much of these docs are still in progress and we're developing them as we go.

### Spinning up a new env

We can spin up an environment by running the `.github/workflows/spinup.yml` script. Go to Actions -> Spin Up Azure environment -> Run workflow -> choose the branch to deploy.

### Destroy the environment

To remove the environment you can run the `.github/workflows/destroy.yml` workflow. Go to Actions -> Destroy Azure environment -> Run workflow -> chose the branch that will destroy the environment.

#### If you destory and spinup

If you destroy and re-create the environment you'll need to update secrets for the newly created accounts. Here is a list of the accounts to reset credentials for by going to Settings -> Secrets

- `ACR_PASSWORD` - Choose the new ACR in Azure, select Access Keys and copy password 2, then update the secret