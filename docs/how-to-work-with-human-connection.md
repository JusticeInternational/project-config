# Introduction

[Human-Connection](https://github.com/JusticeInternational/Human-Connection) is our front-end and back-end core applications that come from the OSS project on Human-Connection and help accelerate our application development for RedSol. We extend Human-Connection to provide a backend and frontend for our users.

We can communicate with the upstream development team for core features on [discord](https://github.com/Human-Connection/Human-Connection#developer-chat). This core base will soon be transformed as well to a different mechanism. When this happens we'll be looking at how we'll adapt. For this reason it's important that we have a log of [issues](https://github.com/JusticeInternational/project-config/issues) for our work so we can track our changes and know what we'll need to adapt.

## Develop Remotely

We also now have the ability to develop remotely using [GitHub Codespaces](https://docs.github.com/en/github/developing-online-with-codespaces). To get started follow these steps:

- Signup for the [beta](https://github.com/features/codespaces/signup)
- Contact us on Whatsapp or open and issue and ping @wenlock so we know what work you'll be doing and we can enable your account
- Use code spaces on https://github.com/JusticeInternational/Human-Connection, you can see [how we do it here](https://github.com/JusticeInternational/Human-Connection/pull/1)

### Run Bootstrap
We have a file in the `.devcontainer` folder which can be used in an interactive shell in codespaces to start up all services:
```bash
$> ./.devcontainer/bootstrap.sh
$> source ./.devcontainer/profile_devcontainer_alias.sh
$> seed
$> ngrok_start
```
Read up more on codespaces setup [here](https://github.com/JusticeInternational/Human-Connection/blob/stable/.devcontainer/README.md).

## Development Setup
Human Connection was setup to use docker containers, and there are several ways we can deploy the webapp and backend using instructions provided in the `./deployment` folder. We'll use `docker` and `docker-compose` commands to make this simple, so, first step:

1. You should have docker and docker-compose installed from www.docker.com
1. Setup security for `./backend` and `./webapp`:
   ```bash
   cd ./backend
   cp ./.env.template ./.env
   cd ../webapp
   cp ./.env.template ./.env
   cd ..
   ```
   The file can be left as is if your development system is secure, otherwise, please tweak the passwords to your liking.
1. If you want to change the defaults, then edit the `.env.template` files directly

### Build the Containers
The DB - `./neo4j`, backend - `./backend` and frontend - `./webapp` folders each have a `Dockerfile` that needs to be built. Build those with these steps:

```
docker-compose build
```


This will create 3 docker containers: DB - `humanconnection/neo4j:latest` , backend - `humanconnection/nitro-backend:latest`, and frontend - `humanconnection/nitro-web:latest`

There is also a maintenance container but the first 3 arre most important.

### Run a Dev instance

1. Change folders to the base of the repository where you see the `docker-compose.yml`
1. Start docker-compose: `docker-compose up`
   ```
    webapp_1       | ✔ Server: Compiled successfully in 38.50s
    webapp_1       | ✔ Client: Compiled successfully in 54.67s
    webapp_1       | ℹ Waiting for file changes
    webapp_1       | ℹ Memory usage: 1.03 GB (RSS: 1.23 GB)
    webapp_1       | ℹ Listening on: http://172.22.0.6:3000/
   ```
1. Start a browser that points to : http://localhost:3000/
1. The backend can also be access at this url: http://localhost:4000/
1. Login with one of the credentials listed [here](https://github.com/JusticeInternational/Human-Connection#live-demo). For example, user - `admin@example.org` and password - `1234`.

### Starting Backend in the background
1. Stop any existing apps running with `docker-compose down` or ctrl-C on the running instance.
1. Run the command ; `docker-compose up -d`

