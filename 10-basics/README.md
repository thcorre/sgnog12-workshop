# Containerlab Basics

This workshop section introduces you to containerlab basics - topology file, image management workflows and lab lifecycle. It is loosely based on the official [Containerlab quickstart](https://containerlab.dev/quickstart/).

## Repository

The repo should be cloned already and you should be in the `ac1-workshop` directory as per the output below:

```
[*]─[rd-13]─[~/clab-workshop/10-basics]
└──>
```

## Topology

The topology file `basic.clab.yml` defines the lab we are going to use in this basics exercise. It consists of the two nodes:

* Nokia SR Linux
* Arista cEOS

The nodes are interconnected with a single link over their respective first Ethernet interfaces.

```yaml
name: basic
topology:
  nodes:
    srl:
      kind: nokia_srlinux
      image: ghcr.io/nokia/srlinux
    ceos:
      kind: arista_ceos
      image: ceos:4.33.1F

  links:
    - endpoints: [srl:e1-1, ceos:eth1]
```

## Deployment

Try to deploy the lab:

```bash
containerlab deploy -t basic.clab.yml
```

Note, you can use a shortcut version of the same command - `sudo clab dep -t basic.clab.yml`.

The deployment should succeed.

## Connecting to the nodes

Connect to the Nokia SR Linux node using the container name:

```bash
ssh clab-basic-{GROUP_ID}-srl
```

Connect to the cEOS node using its IP address (note, the IP might be different in your lab):

```bash
ssh admin@172.20.20.3
```

## Containerlab hosts automation

Containerlab creates `/etc/hosts` entries for each deployed lab so that you can access the nodes using their names. Check the entries:

```bash
cat /etc/hosts
```

## Containerlab ssh config automation

Containerlab creates ssh config entries in `/etc/ssh/ssh_config.d/clab-<lab-name>.conf` file to provide easy access to the nodes. Check the entries:

```bash
cat /etc/ssh/ssh_config.d/clab-basic.conf
```

## Checking network connectivity

SR Linux and cEOS are started with their first Ethernet interfaces connected. Check the connectivity between the nodes:

The nodes also come up with LLDP enabled, our goal is to verify that the basic network connectivity is working by inspecting

```bash
ssh clab-basic-srl
```

and checking the LLDP neighbors on ethernet-1/1 interface

```
show /system lldp neighbor interface ethernet-1/1
```

The expected output should be:

```
--{ running }--[  ]--
A:srl# show /system lldp neighbor interface ethernet-1/1
  +----------+----------+---------+---------+---------+---------+---------+
  |   Name   | Neighbor | Neighbo | Neighbo | Neighbo | Neighbo | Neighbo |
  |          |          |    r    |    r    | r First | r Last  | r Port  |
  |          |          | System  | Chassis | Message | Update  |         |
  |          |          |  Name   |   ID    |         |         |         |
  +==========+==========+=========+=========+=========+=========+=========+
  | ethernet | 00:1C:73 | ceos    | 00:1C:7 | 20      | 16      | Etherne |
  | -1/1     | :46:95:5 |         | 3:46:95 | hours   | seconds | t1      |
  |          | C        |         | :5C     | ago     | ago     |         |
  +----------+----------+---------+---------+---------+---------+---------+
```

## Listing running labs

When you are in the directory that contains the lab file, you can list the nodes of that lab simply by running:

```bash
[*]─[rd-13]─[~/clab-workshop/10-basics]
└──> sudo containerlab inspect
INFO[0000] Parsing & checking topology file: basic.clab.yml
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| # |      Name       | Container ID |         Image         |     Kind      |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| 1 | clab-basic-ceos | c279d892ea22 | ceos:4.32.0F          | arista_ceos   | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 2 | clab-basic-srl  | 7c46eb454f51 | ghcr.io/nokia/srlinux | nokia_srlinux | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
```

If the topology file is located in a different directory, you can specify the path to the topology file:

```bash
[*]─[rd-13]─[/tmp]
└──> sudo containerlab inspect -t ~/clab-workshop/10-basics/
INFO[0000] Parsing & checking topology file: basic.clab.yml
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| # |      Name       | Container ID |         Image         |     Kind      |  State  |  IPv4 Address  |     IPv6 Address     |
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| 1 | clab-basic-ceos | c279d892ea22 | ceos:4.32.0F          | arista_ceos   | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 2 | clab-basic-srl  | 7c46eb454f51 | ghcr.io/nokia/srlinux | nokia_srlinux | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
+---+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
```

You can also list all running labs regardless of where their topology files are located:

```bash
[*]─[rd-13]─[~/clab-workshop/10-basics]
└──> sudo containerlab inspect --all
+---+----------------+----------+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| # |   Topo Path    | Lab Name |      Name       | Container ID |         Image         |     Kind      |  State  |  IPv4 Address  |     IPv6 Address     |
+---+----------------+----------+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
| 1 | basic.clab.yml | basic    | clab-basic-ceos | c279d892ea22 | ceos:4.32.0F          | arista_ceos   | running | 172.20.20.2/24 | 2001:172:20:20::2/64 |
| 2 |                |          | clab-basic-srl  | 7c46eb454f51 | ghcr.io/nokia/srlinux | nokia_srlinux | running | 172.20.20.3/24 | 2001:172:20:20::3/64 |
+---+----------------+----------+-----------------+--------------+-----------------------+---------------+---------+----------------+----------------------+
```

The output will contain all labs and their nodes.

Shortcuts:

* `sudo clab ins` == `sudo containerlab inspect`
* `sudo clab ins -a` == `sudo containerlab inspect --all`

## Lab directory

Lab directory stores the artifacts generated by containerlab that are related to the lab:

* tls certificates
* startup configurations
* inventory files
* topology export json file
* bind mounted directories

To list the contents of the lab directory, run:

```
[*]─[rd-13]─[~/clab-workshop/10-basics]
└──> tree -L 3 clab-basic/
```

## Destroying the lab

When you are done with the lab, you can destroy it. Containerlab can try and find the `*.clab.yml` file in the current directory and use it so that you don't have to type it out.  
Try it:

```bash
sudo clab des --cleanup
```

Alternatively, you could specify the topology file explicitly:

```bash
sudo clab des -t basic.clab.yml --cleanup
```

The `--cleanup` flag ensures that the lab directory gets removed as well.

You finished the basics lab exercise!