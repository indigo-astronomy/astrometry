#!/bin/bash
set -e

# Remember which branch this (astrometry) repo is currently on, so we can
# check out the matching branch in astrometry.net after cloning it.
BRANCH=$(git rev-parse --abbrev-ref HEAD)

cd ..
git clone https://github.com/indigo-astronomy/cfitsio.git
git clone https://github.com/indigo-astronomy/astrometry.net.git

if [ "$BRANCH" != "HEAD" ]; then
	cd astrometry.net
	if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
		echo "Checking out branch '$BRANCH' in astrometry.net"
		git checkout "$BRANCH"
	else
		echo "Branch '$BRANCH' does not exist in astrometry.net; staying on its default branch."
	fi
	cd ..
fi
