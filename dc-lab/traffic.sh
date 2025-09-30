#!/bin/bash
# Copyright 2020 Nokia
# Licensed under the BSD 3-Clause License.
# SPDX-License-Identifier: BSD-3-Clause


set -eu

startTraffic2-1() {
    echo "starting traffic from clab-dc-${GROUP_ID}-client 2 to 1"
    docker exec clab-dc-${GROUP_ID}-client2 bash /config/iperf.sh
}

startTraffic3-1() {
    echo "starting traffic from clab-dc-${GROUP_ID}-clients 3 and 1"
    docker exec clab-dc-${GROUP_ID}-client3 bash /config/iperf.sh
}

startTraffic4-6() {
    echo "starting traffic from clab-dc-${GROUP_ID}-client 4 to 6"
    docker exec clab-dc-${GROUP_ID}-client4 bash /config/iperf.sh
}

startTraffic5-6() {
    echo "starting traffic from clab-dc-${GROUP_ID}-client 5 to 6"
    docker exec clab-dc-${GROUP_ID}-client5 bash /config/iperf.sh
}

startAll() {
    echo "starting traffic on all clab-dc-${GROUP_ID}-clients"
    echo "client2"
    docker exec clab-dc-${GROUP_ID}-client2 bash /config/iperf.sh
    echo "client3"
    docker exec clab-dc-${GROUP_ID}-client3 bash /config/iperf.sh
    # echo "client4"
    # docker exec clab-dc-${GROUP_ID}-client4 bash /config/iperf.sh
}

stopTraffic2-1() {
    echo "stopping traffic between clab-dc-${GROUP_ID}-clients 1 and 2"
    docker exec clab-dc-${GROUP_ID}-client2 pkill iperf3
}

stopTraffic3-1() {
    echo "stopping traffic between clab-dc-${GROUP_ID}-clients 1 and 3"
    docker exec clab-dc-${GROUP_ID}-client3 pkill iperf3
}

stopTraffic4-6() {
    echo "stopping traffic between clab-dc-${GROUP_ID}-clients 6 and 4"
    docker exec clab-dc-${GROUP_ID}-client4 pkill iperf3
}

stopTraffic5-6() {
    echo "stopping traffic between clab-dc-${GROUP_ID}-clients 6 and 5"
    docker exec clab-dc-${GROUP_ID}-client5 pkill iperf3
}

stopAll() {
    echo "stopping all traffic"
    docker exec clab-dc-${GROUP_ID}-client2 pkill iperf3
    docker exec clab-dc-${GROUP_ID}-client3 pkill iperf3
    docker exec clab-dc-${GROUP_ID}-client4 pkill iperf3
    docker exec clab-dc-${GROUP_ID}-client5 pkill iperf3    
}

# start traffic
if [ $1 == "start" ]; then
    if [ $2 == "2-1" ]; then
        startTraffic2-1
    fi
    if [ $2 == "3-1" ]; then
        startTraffic3-1
    fi
    if [ $2 == "4-6" ]; then
        startTraffic4-6
    fi  
    if [ $2 == "5-6" ]; then
        startTraffic5-6
    fi       
    if [ $2 == "all" ]; then
        startAll
    fi
fi

if [ $1 == "stop" ]; then
    if [ $2 == "1-2" ]; then
        stopTraffic2-1
    fi
    if [ $2 == "1-3" ]; then
        stopTraffic3-1
    fi
    if [ $2 == "4-6" ]; then
        stopTraffic4-6
    fi  
    if [ $2 == "5-6" ]; then
        stopTraffic5-6
    fi 
    if [ $2 == "all" ]; then
        stopAll
    fi
fi