#!/bin/sh

TOOL=odb-server
VERSION=`./odb-server --version`

DIR=${TOOL}-${VERSION}
TAR=/tmp/${TOOL}_${VERSION}.tar.gz

git archive --prefix=${DIR}/ HEAD | gzip > ${TAR} && \
echo Archive is ${TAR}

