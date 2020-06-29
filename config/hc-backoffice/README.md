## Development

We're development the backoffice application here for backend of our mobile app. We use the Humman-Connection repository so we'll use this as a basis for our setup.

Here is what we need todo
- [ ] Workflow for making code updates using codespaces for `JusticeInternational/Human-Connection`
- [ ] Workflow for automatically updating the latest containers in `JusticeInternational/project-config`
- [ ] Can we open up more than one tunnel using ngrok?

## Manual Setup
We need to build some containers and publish to the `project-config` repo so we can work with those as a baseline.

## quickstart demo environment
This is some work in progress and we still have some things to work out with this idea, however here is what we can do.
- Startup up a development instance using container repositories in `JusticeInternational/project-config`
- Access the url's using codespaces, and login

To start it, run these commands:

```
cd ./config/hc-backoffice/demo
./bootstrap.sh
```

Double click on the url, and login with credentials from [here](https://github.com/JusticeInternational/Human-Connection#live-demo). For example, user - `admin@example.org` and password - `1234`.

## publishing docker images

We need the docker images for this part, so lets build them first:

You'll need a PAT with write/read permissions to the `JusticeInternational/project-config` repo.

```
export USERNAME=<GitHub username>
export GITHUB_TOKEN=<PAT>
echo $GITHUB_TOKEN | docker login https://docker.pkg.github.com -u $USERNAME --password-stdin
git clone https://github.com/JusticeInternational/Human-Connection
cd Human-Connection
docker-compose build
export REPO=docker.pkg.github.com/justiceinternational/project-config
docker tag humanconnection/nitro-web $REPO/frontend
docker tag humanconnection/nitro-backend $REPO/backend
docker tag humanconnection/neo4j $REPO/db

docker push $REPO/frontend
docker push $REPO/backend
docker push $REPO/db
```

This is all to setup the demo, so we still don't have an automated process for that. We'll need one once we have the workflow figured out.