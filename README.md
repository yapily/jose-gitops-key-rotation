| |Current Status|
|---|---|
|Build|[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fyapily%2Fjose-gitops-key-rotation%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/yapily/jose-gitops-key-rotation/goto?ref=master)|
|Docker Hub|[![](https://images.microbadger.com/badges/version/yapily/jose-gitops-key-rotation.svg)](https://microbadger.com/images/yapily/jose-gitops-key-rotation "Get your own version badge on microbadger.com")|
|License|![license](https://img.shields.io/github/license/yapily/jose-gitops-key-rotation)|

# JOSE key rotation using Gitops principal

Rotate a set of keys, formatted as JWKs and commit them back as encrypted secrets into a git repository, using SOPS.

## Docker image

The docker image is available in docker hub: [https://hub.docker.com/r/yapily/jose-gitops-key-rotation](https://hub.docker.com/r/yapily/jose-gitops-key-rotation)


## How to use the docker image

The Docker image will perform operations on external resources and as a result, requires some configuration.
In particular, you should expect the Docker image to need:
- Access to your git repository where you store your keys as Kubernetes secrets, encrypted with SOPS
- Configuration for SOPS and potential access to your KMS depending on your cloud provider
- Access to your deployments inside the current namespace to restart them once the secret has been updated

### Mount the keys

You will need to mount the folder containing the 3 keys sets into the docker image. 
The docker image is expecting to receive the keys in the folder `/keys`

### Format of the keys

The batch job expects three classifications of keys which are each formatted as a [JWK set](https://tools.ietf.org/html/rfc7517#section-5) following the [JWK standard](https://tools.ietf.org/html/rfc7517):
- `valid-keys`: the keys that are currently valid and should be used for any new entries
- `expired-keys`: the keys that are now expired but should be used to read old entries
- `revoked-keys`: the keys that are now revoked. They are not needed but for good practice, we also keep them to have a history of the keys.

Here is an example of each of the keys: https://github.com/yapily/jose-batch/tree/master/keys

Please follow the same file naming convention!

You don't need to create these files manually as we created another utility to manage these keys: [https://github.com/yapily/jose-cli](https://github.com/yapily/jose-cli)
The output of this CLI can be used as input of this JOSE batch utility.


### Environment variables

#### Access to your git repository

The Docker image will do a commit to your repository, therefore some GIT configurations are required:

- `GIT_USER_EMAIL`: Used by git to set the email of the user that will commit to your repo.
- `GIT_USER_NAME`: Used by git to set the username of the user that will commit to your repo.
- `GIT_REPO`: Used to by git to specify the SSH URL of the git repository.
- `GIT_SECRET_FOLDER`: Used by git to specify the path to the file in therepository where the secret will be committed.
- `GIT_COMMIT_MESSAGE`: Used by git to specifiy the commit message.
- `SOPS_SECRET_ENC_YAML_FILENAME`: Used by SOPS to name the encrypted secret e.g. `secret.enc.yaml`.

#### Setting up the Kubernetes properties

Due to https://github.com/kubernetes/kubernetes/issues/29761, you will need to restart the deployments that depend on the keys as a Kubernetes secret. 
You can do this by setting a value for the label `listener` for each deployment that is dependent on the secret. The image will obtain a list of all the deployments, filter them based on the value of the label `listener` and restart each of the pods in the filtered list. For each deployment that is dependent on the secret, add the label as shown in the example below: 

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    listener: key-rotations
  ...
```

- `NAMESPACE`: Specify the namespace containing the deployments that rely on the encrypted secret.
- `META_KEY_ROTATION_LISTENER`: Specify the value for the `listener` label e.g. `key-rotations`

To give enough time for your choice of CI tool to apply the update to your cluster based on this new commit, the restart of the pods will be delayed by 5 minutes.

#### Setting SOPS

The [documentation for SOPS](https://github.com/mozilla/sops#usage) will inform you which settings are required for your cloud provider.
In our case, we use GKE, and we need to add an environment variables containing the credentials required to access our KMS.

Example:
```
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: /etc/gcp/sa_credentials.json
```
