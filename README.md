# Introduction

This is a place holder for now, we're working on setting up some of our initial configurations for how we'll deploy app components.

Here are some of the working parts:

1. [Setup the backend using Human Connections app](docs/setup-backend.md)
2. [The Venezuela team](https://github.com/orgs/JusticeInternational/teams/venezueladevteam/members) has started a [proto-type android app](docs/setup-android.md).  This will be our focus for end-user interactions. See demo videos following. Individual user: https://youtu.be/m2x6XhZGL103. Provider: https://youtu.be/NHSQN9g7TX8


This project, will be used for [project management](https://github.com/JusticeInternational/project-config/projects/1), [demos](demos/README.md), [docs](docs/README.md), and [automation we use to configure](config/README.md) all the things.

Future apps we'll need may include:

- Updates to Human-Connection to help us develop new data-modesl and helper api's to use within mobile apps.
- We'll have an iOS app

Some references to initial documentation:

- User flows and prototypes: https://www.figma.com/file/nolX6HBTIM4UlNAHnjddcl/Red-Solidaria-Prototype?node-id=1171%3A4
- Data tables structure Version 2 (current): https://docs.google.com/document/d/128Vx0ouMhWwhu5oFXazjv3yq5S0Q2Bjl5WBRCLVjVX4/edit?usp=sharing
- Backlog version 3 (current): https://docs.google.com/spreadsheets/d/1bOGsx9E77-5QbzHp9VJhefdqPriGX5TjfV0589Fn7u8/edit?usp=sharing

See also the subfolder "Reference" in documents for more on initial documentation pertinent to the design of the app

## Deployments

We're using GitHub Actions to deploy. For more information checkout the `.github/workflows` and [read about deployments here](docs/deployments.md)