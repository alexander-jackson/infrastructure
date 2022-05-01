# Kubernetes

Contains the Kubernetes definitions for the cluster running on the `blackboards` server.

## Usage

The server uses [`flux`](https://fluxcd.io/) to synchronise changes made in the
repository through pull requests and automated image updates made through
`flux` itself.

Changes to other repositories will build new images on the `master` branch,
which `flux` will notice, push to this repository and then apply the relevant
change to the server.

## Contents

* `flux-system`: contains the definitions for the services that `flux` uses to
  operate the automation of the cluster
* `shared`: contains the shared services that other applications use, such as
  `nginx` for reverse-proxying, `cert-manager` for SSL certificates and
  `postgres` for database operations
* `apps`: contains the deployments and services that run on the cluster and
  deal with user requests
