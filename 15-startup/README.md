# Startup configuration

This exercise demonstrates how to provide startup configuration to the lab nodes by means of the [`startup-config`](https://containerlab.dev/manual/nodes/#startup-config) field in the topology file.

Startup configuration is a way to provide initial configuration to the lab nodes when they boot up. This is useful when you want to automate the configuration of the nodes and avoid manual intervention. It also brings your lab to a desired state when you need to test a specific scenario.

To enter the lab directory, run the following command from anywhere in your terminal:

```bash
[*]─[clab]─[~]
└──> cd ~/sgnog12-workshop/15-startup/

[*]─[clab]─[~/sgnog12-workshop/15-startup]
└──>
```

We start by deploying a lab defined in the `startup.clab.yml` topology file. The lab consists of two nodes: `srl` (Nokia SR Linux) and `ceos` (Arista cEOS). Both nodes are configured with a startup configuration file that resides in the same directory as the topology file.

We will use the shortened syntax when deploying the lab; less typing and more fun!

```bash
clab dep -c
```
!!! note
    Remember from the basics, when we don't specify the `-t` flag (topology file path) containerlab will search the current directory for a `*.clab.yml` or `*.clab.yaml` file.

    If there are multiple files matching that pattern then you **MUST** use the `-t` flag to specify the topology file path.

Notice that we also use the `-c` flag (`--cleanup`), even though the lab is not deployed this ensures any lab artifacts are deleted and we get a fresh lab coming up.

The startup configuration files - [srl.cfg](srl.cfg) and [ceos.cfg](ceos.cfg) - configure the interfaces, IP addressing, loopbacks and BGP peering between SR Linux and cEOS nodes respectively.

??? info "Expand to see startup configurations"

    === "SR Linux"
        ```
        interface ethernet-1/1 {
            subinterface 0 {
                admin-state enable
                ipv4 {
                    admin-state enable
                    address 192.168.1.1/24 {
                    }
                }
            }
        }
        interface lo0 {
            subinterface 0 {
                admin-state enable
                ipv4 {
                    admin-state enable
                    address 10.10.10.1/32 {
                    }
                }
            }
        }
        network-instance default {
            interface ethernet-1/1.0 {
            }
            interface lo0.0 {
            }
            protocols {
                bgp {
                    admin-state enable
                    autonomous-system 65001
                    router-id 10.10.10.1
                    afi-safi ipv4-unicast {
                        admin-state enable
                    }
                    group ibgp {
                        export-policy [ export-lo ]
                        afi-safi ipv4-unicast {
                            admin-state enable
                        }
                    }
                    neighbor 192.168.1.2 {
                        admin-state enable
                        peer-as 65001
                        peer-group ibgp
                    }
                }
            }
        }
        routing-policy {
            prefix-set loopback {
                prefix 10.10.10.1/32 mask-length-range exact {
                }
            }
            policy export-lo {
                statement 10 {
                    match {
                        prefix {
                            prefix-set loopback
                        }
                    }
                    action {
                        policy-result accept
                    }
                }
            }
        }
        ```

    === "cEOS"
        ```
        hostname {{ .ShortName }}
        username admin privilege 15 secret admin
        !
        service routing protocols model multi-agent
        !
        {{- if .Env.CLAB_MGMT_VRF }}
        vrf instance {{ .Env.CLAB_MGMT_VRF }}
        !
        {{end}}
        {{ if .MgmtIPv4Gateway }}ip route {{ if .Env.CLAB_MGMT_VRF }}vrf {{ .Env.CLAB_MGMT_VRF }} {{end}}0.0.0.0/0 {{ .MgmtIPv4Gateway }}{{end}}
        {{ if .MgmtIPv6Gateway }}ipv6 route {{ if .Env.CLAB_MGMT_VRF }}vrf {{ .Env.CLAB_MGMT_VRF }} {{end}}::0/0 {{ .MgmtIPv6Gateway }}{{end}}
        !
        interface {{ .MgmtIntf }}
        {{ if .Env.CLAB_MGMT_VRF }} vrf {{ .Env.CLAB_MGMT_VRF }}{{end}}
        {{ if .MgmtIPv4Address }}ip address {{ .MgmtIPv4Address }}/{{.MgmtIPv4PrefixLength}}{{end}}
        {{ if .MgmtIPv6Address }}ipv6 address {{ .MgmtIPv6Address }}/{{.MgmtIPv6PrefixLength}}{{end}}
        !
        management api gnmi
        transport grpc default
        {{ if .Env.CLAB_MGMT_VRF }}      vrf {{ .Env.CLAB_MGMT_VRF }}{{end}}
        !
        management api netconf
        transport ssh default
        {{ if .Env.CLAB_MGMT_VRF }}      vrf {{ .Env.CLAB_MGMT_VRF }}{{end}}
        !
        management api http-commands
        no shutdown
        {{- if .Env.CLAB_MGMT_VRF }}
        !
        vrf {{ .Env.CLAB_MGMT_VRF }}
            no shutdown
        {{end}}
        !


        interface Ethernet1
        no switchport
        ip address 192.168.1.2/24
        !
        interface Loopback0
        ip address 10.10.10.2/32
        !
        ip routing
        !
        router bgp 65001
        router-id 10.10.10.2
        neighbor 192.168.1.1 remote-as 65001
        network 10.10.10.2/32
        !

        end
        ```


In particular, the `srl` node is configured to announce its loopback address `10.10.10.1/32` towards the `ceos` node and the `ceos` node is configured to announce its loopback address `10.10.10.2/32` towards the `srl` node.

After the lab is deployed, we can expect that the nodes will boot up and apply the startup configuration snippets provided in the topology file. Consequently, it is fair to assume that the nodes will establish BGP peering and exchange routes.

Let's connect to the `clab-startup-srl` node and check the BGP peering status:

```bash
ssh clab-startup-srl
```

```
--{ running }--[  ]--
A:srl# show network-instance default protocols bgp neighbor 192.168.1.2
```

You should see 1 route sent/received for the aforementioned BGP neighbor.

Now, let's connect to the `clab-startup-ceos` node and make sure that it can reach the loopback address announced by the `srl` node.

```bash
ssh clab-startup-ceos
```

When in the EOS shell, issue a ping towards the `srl` node's loopback address:

```
ping 10.10.10.1
```

You should see a successful ping response.

You have successfully deployed the lab with the nodes equipped with the startup configuration. This is a powerful feature that can be used to provision the nodes with the desired configuration when they boot up.
