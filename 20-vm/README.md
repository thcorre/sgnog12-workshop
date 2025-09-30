# VM-based nodes in containerlab

Unfortunately not every NOS is available in a native containerized format, and many NOSes of today are still VM-based.

However do not fear, as using the [vrnetlab](https://github.com/hellt/vrnetlab) we can package these VM-based NOSes into containers so that they can integrate cleanly into Containerlab.

!!! info
    The vrnetlab used in Containerlab is a fork of the original `vrnetlab/vrnetlab` project. The original project will not work in contianerlab, you must use the fork which has added extensions for better integration into Containerlab, as well as more supported NOSes.

    Go to [containerlab.dev/vrnetlab](https://containerlab.dev/vrnetlab) to quickly navigate to the fork.

Start with cloning the project:

```bash
cd ~ && git clone https://github.com/hellt/vrnetlab.git && \
cd ~/vrnetlab
```

## Building SONiC container image

SONiC image (downloaded from [sonic.software](https://sonic.software/)) is located at `~/images/sonic-vm-202411.qcow2` on your host and should be copied to the `~/vrnetlab/sonic/` directory before building the container image.

```bash
cp ~/images/sonic-vs-202411.qcow2 ~/vrnetlab/sonic/
```

Once copied, we can enter in the `~/vrnetlab/sonic` image and build the container image:

```bash
cd ~/vrnetlab/sonic-vm && make
```

The resulting image will be tagged as `vrnetlab/sonic-vm:202411`. This can be verified using `docker images` command.

```bash
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
vrnetlab/sonic-vm         202411    33b73b1dadc4   5 minutes ago    6.37GB
ceos                      4.33.1F   927c8cd41224   53 minutes ago   2.46GB
ghcr.io/nokia/srlinux     latest    eb2a823cd8ce   8 days ago       2.35GB
```

## Deploying the VM-based nodes lab

With the sonic image built, we can proceed with the lab deployment. We will deploy a lab with SONiC and SR Linux to show that Containerlab can have a VM based docker node and a native docker node in the same lab.

First, let's switch back to the lab directory:

```bash
cd ~/idnog10-workshop/20-vm
```

Now lets deploy the lab:

```bash
clab dep -c
```

At the end of the deployment, the following table will be displayed. Wait for the sonic boot to be completed (see next section), before trying to login to sonic.

```bash
+---+---------------+--------------+--------------------------------+---------------+---------+----------------+----------------------+
| # |     Name      | Container ID |             Image              |     Kind      |  State  |  IPv4 Address  |     IPv6 Address     |
+---+---------------+--------------+--------------------------------+---------------+---------+----------------+----------------------+
| 1 | clab-vm-sonic | c865295f6b4e | vrnetlab/sonic_sonic-vs:202411 | sonic-vm      | running | 172.20.20.3/24 | 3fff:172:20:20::3/64 |
| 2 | clab-vm-srl   | 51b41a280f84 | ghcr.io/nokia/srlinux          | nokia_srlinux | running | 172.20.20.2/24 | 3fff:172:20:20::2/64 |
+---+---------------+--------------+--------------------------------+---------------+---------+----------------+----------------------+
```

### Monitoring the boot process

To monitor the boot process of SONiC, you can open a new terminal and run the following command:

```bash
sudo docker logs -f clab-vm-sonic
```

> the SONiC boot time is approximately 1 minute.

## Connecting to the nodes

To connect to SONiC node:

```bash
ssh admin@clab-vm-sonic
```

Refer to the password in your card.

To connect to SR Linux node:

```bash
ssh clab-vm-srl
```

## Configuring the nodes

Our goal is establish a ping between SR Linux and SONiC devices.

The SONiC device is pre-configured with the link IP address. This can be verified using:

```bash
show runningconfiguration interfaces
```

For reference, here is the configuration for sonic interface `Ethernet0`:

```bash
sudo config interface ip add Ethernet0 10.0.0.0/31
sudo config interface startup Ethernet0
```

Login to SR Linux node and run `enter candidate` to get into configuration edit mode and paste the below lines to configure the interface:

```srl
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.0.1/31
set / network-instance default type default
set / network-instance default interface ethernet-1/1.0
```
Once configured issue the `commit now` command to make sure the candidate config is merged into running.

Now we configured the two systems to be able to communicate with each other. Perform a ping from SONiC to SR Linux:

```bash
admin@sonic:~$ ping 10.0.0.1 -c 3
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=2.00 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=64 time=1.97 ms
64 bytes from 10.0.0.1: icmp_seq=3 ttl=64 time=3.17 ms

--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 1.965/2.378/3.168/0.558 ms
```

We have now completed the section on bring VM based nodes into Containerlab.
