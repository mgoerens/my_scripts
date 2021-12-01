#!/bin/bash

# Usage: ./create_project.sh <full_repo_name> --create_repo|--clone_repo|--existing --install_helm --install_operator_sdk --install_oc --crc_login_enabled --kubeconfig=~/dev/kubeconfigs/my_kubeconfig
#
# Pre-requisites: direnv
# - direnv: Not packages for CentOS / RHEL system, see https://github.com/direnv/direnv/issues/362
# - gh: see https://github.com/cli/cli/blob/trunk/docs/install_linux.md

### Set default values
BASE_DIR="/home/mgoerens/dev"
CREATE_REPO=false
CLONE_REPO=false
INSTALL_HELM=false
INSTALL_OPERATOR_SDK=false
OPERATOR_SDK_VERSION=$(curl -s https://api.github.com/repos/operator-framework/operator-sdk/releases/latest | jq .name | tr -d \")
INSTALL_OC=false
EXISTING=false
REPO_FULL_NAME=""
CRC_LOGIN_ENABLED=false

### Parse arguments

# Get required repo name (also should matches the local directory structure)
if [ "$#" -lt 1 ]; then
  echo "Missing required repository name"
  ## TODO: print Usage (make a function)
  exit 1
fi

REPO_FULL_NAME="$1"
shift 1

while [ "$#" -gt 0 ]; do
  case "$1" in

    --create_repo) CREATE_REPO=true; shift 1;;
    --clone_repo) CLONE_REPO=true; shift 1;;
    --install_helm) INSTALL_HELM=true; shift 1;;
    --install_operator_sdk) INSTALL_OPERATOR_SDK=true; shift 1;;
    --install_operator_sdk=*) INSTALL_OPERATOR_SDK=true; OPERATOR_SDK_VERSION="${1#*=}"; shift 1;;
    --install_oc) INSTALL_OC=true; shift 1;;
    --crc_login_enabled) CRC_LOGIN_ENABLED=true; shift 1;;
    --existing) EXISTING=true; shift 1;;
    --kubeconfig=*) KUBECONFIG_PATH="${1#*=}"; shift 1;;
    # TODO: Install opm: https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/opm-linux.tar.gz
    *) echo "unknown option: $1" >&2; echo "Usage: ./create_project.sh github.com/mgoerens/repo_name --create_repo|--clone-repo|--existing --install_helm --install_operator_sdk --install_oc --crc_login_enabled --kubeconfig=~/dev/kubeconfigs/my_kubeconfig" && exit 1;;
  esac
done

### Arg validation
if [ ! -d $BASE_DIR ]; then
  echo "Base directory $BASE_DIR doesn't exist"
  exit 1
fi

FULL_REPO_PATH="$BASE_DIR/$REPO_FULL_NAME"

# Test if dir already exists
if [[ -d $FULL_REPO_PATH && "$EXISTING" = "false" ]]; then
  echo "Directory $REPO_FULL_NAME already exists in $BASE_DIR"
  exit 1
fi

REPO_MANAGER=$(cut -d / -f 1 <<< "$REPO_FULL_NAME")
REPO_ORG_NAME=$(cut -d / -f 2 <<< "$REPO_FULL_NAME")
REPO_NAME=$(cut -d / -f 3 <<< "$REPO_FULL_NAME")
SHOULD_NOT_UNPACKED=$(cut -d / -f 4 <<< "$REPO_FULL_NAME")
if [[ -z "$REPO_MANAGER" || -z "$REPO_ORG_NAME" || -z "$REPO_NAME" || -n "$SHOULD_NOT_UNPACKED" ]]; then
  echo "Malformatted repository name. Should be for instance \"gitlab.com/my_org/my_project\""
  exit 1
fi

if [[ ! "$REPO_MANAGER" == "github.com" && ! "$REPO_MANAGER" == "gitlab.com" ]]; then
  echo "Unsupported repository manager. Use github.com or gitlab.com."
  exit 1
fi

if [[ "$CREATE_REPO" = "true" && "$CLONE_REPO" = "true" ]]; then
  echo "Cannot both create and clone repo - choose one !"
  exit 1
fi

if [ "$EXISTING" = "true" ]; then
  if [[ "$CREATE_REPO" = "true" || "$CLONE_REPO" = "true" ]]; then
    echo "Cannot create or clone the repository if the project already exists"
  fi
fi

### Create dir, init repo, install packages, and configure direnv

echo "----Create basic directory structure and add binary directory in .envrc"

if [ "$EXISTING" = "false" ]; then

  if [ "$CLONE_REPO" = "true" ] ; then
    echo "Cloning repository $REPO_FULL_NAME"

    mkdir -p "$REPO_MANAGER"/"$REPO_ORG_NAME"
    cd "$BASE_DIR"/"$REPO_MANAGER"/"$REPO_ORG_NAME" || exit

    ## example github: git@github.com:opdev/synapse-operator.git
    ## example gitlab: git@gitlab.com:mgoerens/test_ci.git
    # This will also created the directory
    git clone "git@$REPO_MANAGER:$REPO_ORG_NAME/$REPO_NAME.git"
    cd "$FULL_REPO_PATH" || exit
  else
    mkdir -p "$FULL_REPO_PATH"
    cd "$FULL_REPO_PATH" || exit
    git init
  fi

  if [ "$CREATE_REPO" = "true" ] ; then
    echo "Creating repository $REPO_FULL_NAME"

    ## TODO: Add posibility to create repo online in a later step (independant from init)
    case "$REPO_MANAGER" in
      github.com)
        # This automatically creates the repo and adds the new remote
        # TODO: automatic login
        gh repo create --private -y "$REPO_ORG_NAME"/"$REPO_NAME";;
      gitlab.com)
        # This only adds the new remote. The repo will actually be created at the first push
        # TODO: is there a gitlab cli ?
        git remote add origin git@"$REPO_FULL_NAME".git;;
    esac
  fi
else
  cd "$FULL_REPO_PATH" || exit
fi

# TODO: only create .bin if necessary
# TODO: what if .bin already exists in cloned repo ?
mkdir "$FULL_REPO_PATH/.bin"
echo "export PATH=\$PATH:$FULL_REPO_PATH/.bin" >> .envrc

GIT_EXCLUDE_PATH="$FULL_REPO_PATH/.git/info/exclude"
if [ -f "$GIT_EXCLUDE_PATH" ]; then
  echo ".bin" >> "$GIT_EXCLUDE_PATH"
  echo ".envrc" >> "$GIT_EXCLUDE_PATH"
fi

direnv allow

# TODO: set helm version
if [ "$INSTALL_HELM" = "true" ]; then
  echo "----Install Helm"
  
  # Download binary
  wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
  tar -zxvf helm-v3.6.0-linux-amd64.tar.gz 
  mv linux-amd64/helm .bin/
  rm -rf linux-amd64/
#  helm version
  rm helm-v3.6.0-linux-amd64.tar.gz

  # TODO: NOT TESTED
  # if [ -f $FULL_REPO_PATH/.helmignore ]; then
  #   echo ".bin/" >> $FULL_REPO_PATH/.helmignore
  #   echo ".envrc" >> $FULL_REPO_PATH/.helmignore
  #   echo "KUBECONFIG" >> $FULL_REPO_PATH/.helmignore
  # fi

  # Configure direnv
  # TODO: check Helm cache path
fi

# Adapted procedure from: https://sdk.operatorframework.io/docs/installation/
if [ "$INSTALL_OPERATOR_SDK" = "true" ]; then
  echo "----Install the Operator SDK"
  echo "----Version: $OPERATOR_SDK_VERSION"

  # Download binary
  ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n "$(uname -m)" ;; esac)
  OS=$(uname | awk '{print tolower($0)}')
  OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_VERSION}
  curl -LO "${OPERATOR_SDK_DL_URL}"/operator-sdk_"${OS}"_"${ARCH}"
  gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
  curl -LO "${OPERATOR_SDK_DL_URL}"/checksums.txt
  curl -LO "${OPERATOR_SDK_DL_URL}"/checksums.txt.asc
  gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
  grep operator-sdk_"${OS}"_"${ARCH}" checksums.txt | sha256sum -c -
  chmod +x operator-sdk_"${OS}"_"${ARCH}" && mv operator-sdk_"${OS}"_"${ARCH}" .bin/operator-sdk
  rm checksums.txt*
fi

if [ "$INSTALL_OC" = "true" ]; then
  echo "----Install oc"

  wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
  tar -zxvf openshift-client-linux.tar.gz -C .bin/
  rm openshift-client-linux.tar.gz .bin/README.md

  echo "source <(kubectl completion bash)" >> .envrc

  direnv allow
fi

if [ "$CRC_LOGIN_ENABLED" = "true" ]; then
  echo "----Add automatic login to CRC"

  # use first: crc config set kubeadmin-password <password_you_prefer>
  cat << EOF >> .envrc
if [ \`crc status | awk '{if (\$1 == "OpenShift:") print \$2}'\` == "Running" ]; then
  export PATH="/home/mgoerens/.crc/bin/oc:\$PATH"
  oc login -u kubeadmin -p kubeadmin https://api.crc.testing:6443
fi
EOF

  direnv allow
fi

if [ -n "$KUBECONFIG_PATH" ]; then
  ## TODO: test if path exists to avoid failing on cp
  ## TODO: store in .kube/config instead
  cp -v "$KUBECONFIG_PATH" "$FULL_REPO_PATH/KUBECONFIG"
  chmod 600 "$FULL_REPO_PATH/KUBECONFIG"
  echo "export KUBECONFIG=$FULL_REPO_PATH/KUBECONFIG" >> .envrc
  direnv allow
  if [ -f "$GIT_EXCLUDE_PATH" ]; then
    echo "KUBECONFIG" >> "$GIT_EXCLUDE_PATH"
  fi
fi

