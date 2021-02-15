#!/usr/bin/env bash

# Rotate the keys injected as secrets

## Base64 the keys to allow a grep replace on the secret.yaml after
VALID_KEYS_BEFORE=$(cat /keys/valid-keys.json | base64 --wrap=0)
EXPIRED_KEYS_BEFORE=$(cat /keys/expired-keys.json | base64 --wrap=0)
REVOKED_KEYS_BEFORE=$(cat /keys/revoked-keys.json | base64 --wrap=0)

## Rotate the keys
jose jwks-sets rotate -k /keys -o /tmp/keys $JOSE_CLI_OPTIONS

## The new base64 values we need to replace in the secret
VALID_KEYS_NEW=$(cat /tmp/keys/valid-keys.json | base64 --wrap=0)
EXPIRED_KEYS_NEW=$(cat /tmp/keys/expired-keys.json | base64 --wrap=0)
REVOKED_KEYS_NEW=$(cat /tmp/keys/revoked-keys.json | base64 --wrap=0)


#Gitops show time

## Setup git
git config --global user.email $GIT_USER_EMAIL
git config --global user.name $GIT_USER_NAME

## Clone the repo
### Add the SSH key to access the repo
./add-ssh-key.sh

git clone ${GIT_REPO}
## Go the folder where the keys are stored as encrypted secrets
cd ${GIT_SECRET_FOLDER}

## Decrypt the secrets using SOPS
sops -d ${SOPS_SECRET_ENC_YAML_FILENAME} > secret.yaml

## Replace the old keys as base64 with the new keys as base64
sed "s/valid-keys: ${VALID_KEYS_BEFORE}/valid-keys: ${VALID_KEYS_NEW}/g" secret.yaml > tmpfile && mv tmpfile secret.yaml
sed "s/expired-keys: ${EXPIRED_KEYS_BEFORE}/expired-keys: ${EXPIRED_KEYS_NEW}/g" secret.yaml > tmpfile && mv tmpfile secret.yaml
sed "s/revoked-keys: ${REVOKED_KEYS_BEFORE}/revoked-keys: ${REVOKED_KEYS_NEW}/g" secret.yaml > tmpfile && mv tmpfile secret.yaml

## Re-encrypt the secrets
sops -e secret.yaml > ${SOPS_SECRET_ENC_YAML_FILENAME}

## Commit the change
git add ${SOPS_SECRET_ENC_YAML_FILENAME}
git commit -m "${GIT_COMMIT_MESSAGE}"
git push origin master

if [[ -z "${NAMESPACE}" ]]; then
    echo "No specific namespace to filter"
    NAMESPACES_FILTER="--all-namespaces"
else
    echo "Filter for namespace ${NAMESPACE}"
    NAMESPACES_FILTER="-n ${NAMESPACE}"
fi

# Restarting deployments using the keys *
# * Due to https://github.com/kubernetes/kubernetes/issues/29761, we will need to restart the deployments using the secret
DEPLOYMENTS_TO_RESTART=$(kubectl get deployment  -l listener=${META_KEY_ROTATION_LISTENER} --template '{{range .items}}{{.metadata.name}}{{" "}}{{.metadata.namespace}}{{"\n"}}{{end}}' "${NAMESPACES_FILTER}")
if [ -z "${DEPLOYMENTS_TO_RESTART:-}" ]; then
  echo "No deployment listening to '${META_KEY_ROTATION_LISTENER}'"
else
  # Lets give a bit of time for argoCD to deploy
  sleep 5m
  for deploy ns in $(echo "$DEPLOYMENTS_TO_RESTART") ; do
    echo "Deployments to restart: $deploy in namespace $ns"
    kubectl rollout restart deployment ${deploy} -n $ns
  done
fi
