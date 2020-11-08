# Development
Here are some of the bootstraping notes for setting up [Human Connections](https://github.com/JusticeInternational/Human-Connection).
Things that help us here:

- A social networking platform that comes with a baked backend-data-model
- A standard API mechanism to query the data-model using GraphQL

[Human Connections](https://github.com/JusticeInternational/Human-Connection) is a forked repo and is maintained as an Open Source Project. We will use it to develop our backend and social network. Upstream updates are maintained on `master`, with stable releases being deployed from `stable`. Any enhancments we make will be delivered to `stable` and PR'd back to the upstream repo for contributions.

## Build
- Clone the Human Connections repo: `git clone https://github.com/JusticeInternational/Human-Connection`

## Deploying to a Stage Environment

## Deployment to Production
- We're using GitHub Actions to deploy this app.
- First we need to deploy the backend with `.github/workflows/spinup-destroy.yml`
- Then we need to setup ACR service [principles here](how-do-i-setup-acr.md)
- Finally make changes and merge to master so we can deploy `config/docker-compose.yml` with AZ Web Apps
