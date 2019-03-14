#!/bin/bash
# -*- mode: shell-script; fill-column: 80; -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2019, Joyent, Inc.
#

export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -o xtrace

SOURCE="${BASH_SOURCE[0]}"
if [[ -h $SOURCE ]]; then
    SOURCE="$(readlink "$SOURCE")"
fi
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SVC_ROOT=/opt/triton/logarchiver

LOGARCHIVER_CFG=$SVC_ROOT/etc/config.json
ZONE_UUID=`/usr/bin/zonename`

export PATH=$SVC_ROOT/build/node/bin:/opt/local/bin:/usr/sbin/:/usr/bin:$PATH

CONFIG_AGENT_LOCAL_MANIFESTS_DIRS=$SVC_ROOT

# Include common utility functions (then run the boilerplate)
source /opt/smartdc/boot/lib/util.sh
sdc_common_setup

# set up services
svccfg import /opt/smartdc/hermes/smf/hermes.xml
svccfg import /opt/smartdc/hermes/smf/hermes-proxy.xml

# add log rotation entries for services
sdc_log_rotation_add amon-agent /var/svc/log/*amon-agent*.log 1g
sdc_log_rotation_add config-agent /var/svc/log/*config-agent*.log 1g
sdc_log_rotation_add hermes /var/svc/log/*hermes:default.log 1g
sdc_log_rotation_add hermes-proxy /var/svc/log/*hermes-proxy:default.log 1g
sdc_log_rotation_setup_end

# All done, run boilerplate end-of-setup
sdc_setup_complete


exit 0
