# IDNOG 10 DC Lab

!!! info "Disclaimer"
    This lab is based on [srl-sros-telemetry-lab](https://github.com/srl-labs/srl-sros-telemetry-lab). (Kudos to Marlon Paz, Roman Dodin and Kevin Todts). 
    
We have modified the lab for this workshop to better align with the latest DC best practices (IPv6 underlay infra, Usage of BGP unnumbered underlay with IPv6 link-locals, BFD sessions used on eBGP peers, optimized BGP timers etc.) and to also demonstrate additional EVPN capabilities like All-Active multihoming.

This lab represents a small Clos DC fabric with [Nokia SR Linux](https://learn.srlinux.dev/) switches running as containers.

Goals of this lab:

1. Demonstrate how a telemetry stack can be incorporated into the same clab topology file.
2. Explain SR Linux wholistic telemetry support.
3. Provide practical configuration examples for the gnmic collector to subscribe to fabric nodes and export metrics to Prometheus TSDB.

## Deploying the lab

The lab is deployed with [containerlab](https://containerlab.dev) project.

```bash
# deploy a lab
clab deploy
```

Once the lab is completed, it can be removed with the destroy command.

```bash
# destroy a lab
clab destroy
```

## Accessing the network elements

Once the lab has been deployed, the different SR Linux and SROS nodes can be accessed via SSH through their management IP address, given in the table displayed after successful deployment of the Containerlab topology.

!!! tip
    Instead of using the IP addres to connect to the nodes, you can use the node hostname.

    For example
    ```bash
    # reach a SR Linux leaf or a spine via SSH
    ssh admin@leaf1
    ssh admin@spine1
    ```

You can't SSH into the linux nodes. You must enter the shell using the `docker exec` command. Refer to the example below.


```bash
# reach a Linux client via Docker
docker exec -it client1 bash
```

## Fabric configuration

The DC fabric used in this lab consists of three leaf nodes and two spine nodes interconnected with each other as shown in the diagram.

![pic1](../idnog10-workshop-topology.png)

Leaf and spine nodes use Nokia SR Linux IXR-D2L and IXR-D3L chassis respectively. Each network element of this topology is equipped with a [fabric startup configuration file](configs/fabric) that is applied at the node's startup.

Once booted, network nodes will come up with interfaces, underlay protocols and overlay service configured. The fabric is configured with Layer 2 EVPN service between the leaf nodes.

### Verifying the underlay and overlay status

The underlay network is provided by eBGP, and the overlay network, by iBGP. By connecting via SSH to one of the leaf nodes, it is possible to verify the status of those BGP sessions.

```
A:leaf1# /show network-instance protocols bgp neighbor
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BGP neighbor summary for network-instance "default"
Flags: S static, D dynamic, L discovered by LLDP, B BFD enabled, - disabled, * slow
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
+------------------------+-----------------------------------+------------------------+--------+-------------+--------------------+--------------------+-----------------+-----------------------------------+
|        Net-Inst        |               Peer                |         Group          | Flags  |   Peer-AS   |       State        |       Uptime       |    AFI/SAFI     |          [Rx/Active/Tx]           |
+========================+===================================+========================+========+=============+====================+====================+=================+===================================+
| default                | 10.0.2.1                          | overlay                | SB     | 64512       | established        | 0d:0h:7m:43s       | evpn            | [9/9/2]                           |
|                        |                                   |                        |        |             |                    |                    | ipv4-unicast    | [8/2/1]                           |
|                        |                                   |                        |        |             |                    |                    | ipv6-unicast    | [0/0/0]                           |
| default                | 10.0.2.2                          | overlay                | SB     | 64512       | established        | 0d:0h:2m:4s        | evpn            | [9/0/2]                           |
|                        |                                   |                        |        |             |                    |                    | ipv4-unicast    | [7/2/6]                           |
|                        |                                   |                        |        |             |                    |                    | ipv6-unicast    | [0/0/0]                           |
| default                | fe80::186c:eff:feff:1%ethernet-   | underlay               | DB     | 65500       | established        | 0d:0h:0m:9s        | evpn            | [0/0/0]                           |
|                        | 1/49.0                            |                        |        |             |                    |                    | ipv4-unicast    | [5/5/1]                           |
|                        |                                   |                        |        |             |                    |                    | ipv6-unicast    | [0/0/0]                           |
| default                | fe80::18a2:fff:feff:1%ethernet-   | underlay               | DB     | 65500       | established        | 0d:0h:0m:6s        | evpn            | [0/0/0]                           |
|                        | 1/50.0                            |                        |        |             |                    |                    | ipv4-unicast    | [5/5/6]                           |
|                        |                                   |                        |        |             |                    |                    | ipv6-unicast    | [0/0/0]                           |
+------------------------+-----------------------------------+------------------------+--------+-------------+--------------------+--------------------+-----------------+-----------------------------------+
Summary:
2 configured neighbors, 2 configured sessions are established, 0 disabled peers
2 dynamic peers
```

## Running traffic

To run test traffic through the fabric, we can leverage `traffic.sh` control script.

To start the traffic:

* `bash traffic.sh start all` - start traffic between all nodes
* `bash traffic.sh start 1-3` - start traffic between client1 and client3
* `bash traffic.sh start 2-4` - start traffic between client2 and client4

To stop the traffic:

* `bash traffic.sh stop all` - stop traffic generation between all nodes
* `bash traffic.sh stop 1-3` - stop traffic generation between client1 and client3
* `bash traffic.sh stop 2-4` - stop traffic generation between client2 and client4

## Telemetry stack

SR Linux has first-class streaming telemetry support thanks to 100% YANG coverage of state and config data. 

The wholistic coverage enables SR Linux users to stream **any** data off of the NOS with on-change, sample, or target-defined support. A discrepancy in visibility across APIs is not about SR Linux.

Telemetry is at the core of this lab. The following stack of software solutions has been chosen for it:

| Role                | Software                              |
| ------------------- | ------------------------------------- |
| Telemetry collector | [gnmic](https://gnmic.openconfig.net) |
| Time-Series DB      | [prometheus](https://prometheus.io)   |
| Visualization       | [grafana](https://grafana.com)        |

## Grafana

Grafana is a key component of this lab. The lab topology file includes grafana node along with its configuration parameters such as dashboards, datasources and required plugins.

The Grafana dashboard provided by this repository provides multiple views on the collected real-time data. Powered by the [flowchart plugin](https://grafana.com/grafana/plugins/agenty-flowcharting-panel/), it overlays telemetry sourced data over graphics such as topology and front panel views of the devices.

![pic3](https://user-images.githubusercontent.com/86619221/205601697-bd5b68f0-e2c6-49d3-a1f3-1cb5b67b34d9.JPG)

Using the flowchart plugin and real telemetry data users can create interactive topology maps (aka weathermap) with a visual indication of link rate/utilization.

![pic2](https://user-images.githubusercontent.com/86619221/205601728-f3b254d1-2b03-4e75-b0e4-eb89cf54789a.JPG)

## Access details

* Grafana: <http://localhost:3000>. Built-in user credentials: `admin/admin`
* Prometheus: <http://localhost:9090/graph>
