#!/usr/bin/env bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"


#################################
# Setup Git defaults for success

# Use git hooks defined in this repository
git config core.hooksPath scripts/git-hooks

# Never fast-forward merges; if `git merge` is being used, it's because we deliberately want a merge commit
git config merge.ff false

# Always rebase when pulling
git config pull.rebase true

# Only push the current branch
git config push.default simple



################################
# Ensure docker is installed

if ! command -v docker &> /dev/null
then
    echo "Please install Docker Desktop from:"
    echo "https://docs.docker.com/desktop/install/mac-install/"
    exit 1
fi


################################
# Ensure toast is installed

if ! command -v toast &> /dev/null
then
    echo "Please install toast; you can use one of:"
    echo "  brew install toast"
    echo "  port install toast"
    echo "  cargo install toast"
    echo "or download from"
    echo "  https://github.com/stepchowfun/toast"
    exit 1
fi

echo "Successfully setup!"
exit 0
