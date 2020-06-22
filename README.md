# JOSE key rotation the gitops way

Rotate a set of Keys, formatted as JWK and commit them back as encrypted secrets into a git repository, using SOPS.

## Environment variables

- GIT_USER_EMAIL
- GIT_USER_NAME
- NAMESPACE
- META_KEY_ROTATION_LISTENER
- GIT_REPO
- GIT_SECRET_FOLDER
- GIT_COMMIT_MESSAGE
- SOPS_SECRET_ENC_YAML_FILENAME