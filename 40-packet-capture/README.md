# Packet capture

Every network labbing software must provide its users with the packet capturing abilities. Looking at the frames as they traverse the network links is not only educational, but also helps to troubleshoot the issues that might arise during the lab development.

Containerlab offers a simple way to capture the packets from any interface of any node in the lab since every interface is exposed to the underlying Linux OS. This article will explain how to do that.

Everything we are going to do in this exercise is explained in details in the [Containerlab documentation](https://containerlab.dev/manual/wireshark/).

## Remote capture

The first way to capture the packets from a containerlab node running on a remote host that we are going to explore is called "remote capture". In this scenario a user has a network connectivity (ssh) to the host that runs containerlab topology and wishes to get the packet capture displayed in the Wireshark running locally.

To achieve this, we will execute the `tcpdump` command on the remote host and pipe the output to the local Wireshark app. Here is a command that does it all for the host `d1` which is the instructors host.

It captures the traffic from SR OS (`clab-vm-sros`) port `eth1` (`1/1/1`) running on `d1` host and displaying the capture in the Wireshark.

<small>The command is provided for WSL and Mac systems, assuming default Wireshark installation path</small>

Windows/WSL:

```bash
ssh root@{public_IP} \
"ip netns exec clab-vm-sros tcpdump -U -nni eth1 -w -" | \
/mnt/c/Program\ Files/Wireshark/wireshark.exe -k -i -
```

macOS:

```
ssh root@{public_IP} \
"ip netns exec clab-vm-sros tcpdump -U -nni eth1 -w -" | \
/Applications/Wireshark.app/Contents/MacOS/Wireshark  -k -i -
```

## Visual Studio Code

`tcpdump` is great, but what we really want to see is that Wireshark window we know and love.

Thanks to the VS Code extension, you can capture as many packets as you wish without even changing applications.

Open the extension pane and expand the tree view on the left hand side to drill down to the interface level.

Upon hovering on an interface, you should see shark icon. Click the shark icon and watch as the magic happens and wireshark opens right inside of VS Code.

![](https://gitlab.com/rdodin/pics/-/wikis/uploads/752c161fe4e66750a35e0031e7e7d2f7/vscode_wireshark_vnc.gif)

Under the hood this relies on the Edgeshark integration, which is discussed next.

## Edgeshark

[Edgeshark](https://edgeshark.siemens.io/#/) is a set of tools that offer (among many things) a Web UI that displays every interface of every container and can start a wireshark as easy as clicking a button.

Edgeshark installation consists of two parts:

1. A service that runs on the host that runs containerlab topologies
2. A wireshark capture plugin that runs next to the Wireshark on a user's PC

To install the service, past the installer command that uses docker compose to deploy the service:

```bash
curl -sL \
https://github.com/siemens/edgeshark/raw/main/deployments/wget/docker-compose.yaml | \
docker compose -f - up -d
```

Now, you have to install the client plugin based on the OS of your PC.

### Windows

Windows users get to enjoy a simple installer-based workflow that installs the URL handler and the Wireshark plugin in one go.

Download the [installer archive](https://github.com/siemens/cshargextcap/releases/download/v0.10.7/cshargextcap_0.10.7_windows_amd64.zip).

Unzip the archive and launch the installer.

### MacOS

MacOS users have to suffer a little. But it is not that bad either.

To install the URL handler paste the following in the Mac terminal app:

```bash
mkdir -p /tmp/pflix-handler && cd /tmp/pflix-handler && \
rm -rf packetflix-handler.zip packetflix-handler.app __MACOSX && \
curl -sLO https://github.com/srl-labs/containerlab/files/14278951/packetflix-handler.zip && \
unzip packetflix-handler.zip && \
sudo mv packetflix-handler.app /Applications
```

To install the extcap wireshark plugin execute in the Mac terminal:

```bash
# for x86_64 MacOS use https://github.com/siemens/cshargextcap/releases/download/v0.10.7/cshargextcap_0.10.7_darwin_amd64.tar.gz
DOWNLOAD_URL=https://github.com/siemens/cshargextcap/releases/download/v0.10.7/cshargextcap_0.10.7_darwin_arm64.tar.gz
mkdir -p /tmp/pflix-handler && curl -sL $DOWNLOAD_URL | tar -xz -C /tmp/pflix-handler && \
open /tmp/pflix-handler && open /Applications/Wireshark.app/Contents/MacOS/extcap
```

The command above will open two Finder windows, one with the `cshargextcap` binary and the other with the Wireshark's existing plugins. Move the `cshargextcap` file over to the window with Wireshark plugins.

### VS Code

To access the Edgeshark UI, you can open it from Containerlab VS code extension.
