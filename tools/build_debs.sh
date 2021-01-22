#!/bin/bash

# Copyright (c) 2019 CloudMakers, s. r. o.
# All rights reserved.
#
# You can use this software under the terms of 'INDIGO Astronomy
# open-source license'
# (see https://github.com/indigo-astronomy/indigo/blob/master/LICENSE.md).
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

echo FROM $1 >Dockerfile
cat >>Dockerfile <<EOF
LABEL maintainer="peter.polakovic@cloudmakers.eu"
RUN apt-get -y update && apt-get -y install wget unzip build-essential autoconf autotools-dev libtool
COPY indigo-astrometry-$3.tar.gz .
RUN tar -zxf indigo-astrometry-$3.tar.gz
RUN rm indigo-astrometry-$3.tar.gz
WORKDIR indigo-astrometry-$3
RUN make package
EOF
docker build -t indigo-astrometry .
docker create --name indigo-astrometry indigo-astrometry
docker cp indigo:/indigo-astrometry-$3/$2 .
docker container rm indigo-astrometry
docker image rm indigo-astrometry
rm Dockerfile
