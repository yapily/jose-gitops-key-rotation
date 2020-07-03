| |Current Status|
|---|---|
|Build|[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fyapily%2Fjose-gitops-key-rotation%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/yapily/jose-gitops-key-rotation/goto?ref=master)|
|Docker Hub|[![](https://images.microbadger.com/badges/version/yapily/jose-gitops-key-rotation.svg)](https://microbadger.com/images/yapily/jose-gitops-key-rotation "Get your own version badge on microbadger.com")|
|License|![license](https://img.shields.io/github/license/yapily/jose-gitops-key-rotation)|

# JOSE key rotation using Gitops principal

Rotate a set of Keys, formatted as JWKs and commit them back as encrypted secrets into a git repository, using SOPS.

## Docker image

The docker image is available in docker hub: [https://hub.docker.com/r/yapily/jose-gitops-key-rotation](https://hub.docker.com/r/yapily/jose-gitops-key-rotation)


## How to use the docker image

The docker will do some operation on external resources and would therefore requires some configuration.
In particular, you should expect the docker image to need:
- Access your git repository where you store your keys as Kubernetes secrets, encrypted with SOPS
- Using SOPS and potentially access to your KMS for that
- Access your deployments inside the current namespace, to restart them once the secret has been updated

### Mount the keys

You will need to mount the folder containing the 3 keys sets into the docker image. 
The docker image is expecting to receive the keys in the folder `/keys`

### Format of the keys

The batch is expecting the keys to be format as JWK set, and categorised in three different status:
- `valid-keys`: the keys that are currently valid and should be used for any new entries
- `expired-keys`: the keys that are now expired but should be used to read old entries
- `revoked-keys`: the keys that are now revoked. They are not needed but by good practice, we also keep them to not loose the history.

The keys follow the [JWK standard](https://tools.ietf.org/html/rfc7517) and a set of keys would be cover on [section 5](https://tools.ietf.org/html/rfc7517#section-5).
You got an example of keys in here: https://github.com/yapily/jose-batch/tree/master/keys

Please follow the same file name convention!

You don't need to create those files manually, we actually created another utility to manage those keys: [https://github.com/yapily/jose-cli](https://github.com/yapily/jose-cli)
The output of this CLI can be used as input of this JOSE batch utility.


### Environment variables

#### Access to your git repository

The docker image will do a commit to your repository. Therefore some GIT configuration are required:

- `GIT_USER_EMAIL`: The email you want the key rotation commit to use
- `GIT_USER_NAME` : The username of the git user that will do the key rotation commit
- `GIT_REPO` : The SSH URL of the git repository
- `GIT_SECRET_FOLDER`: Inside the git repository, you must have put the secret.enc.yaml to a sub folder. Specify here the sub folder to the secret.enc.yaml
- `GIT_COMMIT_MESSAGE`: The commit message you want this docker to use when rotating the keys and committing back to the git repository
- `SOPS_SECRET_ENC_YAML_FILENAME`: Using SOPS, you may have name your encrypted secret with a speficic name. Setup here the name of the secret, like `secret.enc.yaml`.

#### Setting up the Kubernetes properties

Due to https://github.com/kubernetes/kubernetes/issues/29761, we will need to restart the deployments that depends of the keys as Kubernetes secret. 
The way we did it is by having the pod listing the different deployments dependent of the keys, filtered using an annotation, and restart all of them. 
In order to leave your current CD implementation to get trigger based on this new commit, the restart of the deployments will be delayed of 5 minutes.
This requires that your applications, which depends on those keys, would need to be have an annotation added to their manifest. An example:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    listener: key-rotations
```

- `NAMESPACE`: We would need to rotate the deployments that relies on those keys to be restarted. Specify here the namespace of those deployments.
- `META_KEY_ROTATION_LISTENER`: The value you choose for the `listener` annotation. In the example above: `key-rotations`

#### Setting SOPS

The [documentation of SOPS](https://github.com/mozilla/sops#usage) will point you of the settings required depending of your cloud provider.
In our case, we use GKE, the way to proceed is to add an environment variables containing the credential required to access our KMS.
Example:
```
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: /etc/gcp/sa_credentials.json
```
