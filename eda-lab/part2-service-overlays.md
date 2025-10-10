# 🔄 Part 2: Service Overlays - L2 EVPN Service

> **Building Layer 2 EVPN-VXLAN Services on Your EDA Fabric**

Now that your underlay fabric is operational, this guide walks you through creating **Layer 2 EVPN overlay services** using Bridge Domains and Bridge Interfaces to provide Layer 2 connectivity between workloads regardless of their physical location.

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [L2 EVPN Concepts](#-l2-evpn-concepts)
4. [Exercise 2: Create L2 EVPN Instance](#-exercise-2-create-l2-evpn-instance)
   - [Step 1: Create Bridge Domain](#step-1-create-bridge-domain)
   - [Step 2: Create Bridge Interfaces](#step-2-create-bridge-interfaces)
5. [Exercise 3: Verify L2 EVPN Service](#-exercise-3-verify-l2-evpn-service)
   - [Step 1: View Bridge Domain Summary](#step-1-view-bridge-domain-summary)
   - [Step 2: Test End-to-End Connectivity](#step-2-test-end-to-end-connectivity)
   - [Step 3: Verify Device Configuration](#step-3-verify-device-configuration)
   - [Step 4: Check MAC Learning](#step-4-check-mac-learning)
6. [Alternative Method: Virtual Networks](#-alternative-method-virtual-networks)
7. [Troubleshooting & Tips](#%EF%B8%8F-troubleshooting--tips)
8. [What's Next?](#-whats-next)

---

## 🎯 Overview

In this lab, you will create a Layer 2 EVPN overlay service to connect two clients (c1 and c2) across different leaf switches using Bridge Domains and Bridge Interfaces.

**Lab Scenario:**
- Client1 connected to leaf1 on interface ethernet-1/1
- Client2 connected to leaf2 on interface ethernet-1/1
- Client3 connected to leaf3 on interface ethernet-1/1
- All clients are untagged
- Layer 2 connectivity via EVPN-VXLAN overlay

**What you'll learn:**  
✅ Create Bridge Domains for L2 EVPN services  
✅ Configure Bridge Interfaces to attach workloads  
✅ Allocate VNI, EVI, and Tunnel Index from pools  
✅ Verify EVPN-VXLAN operation and MAC learning  
✅ Test end-to-end Layer 2 connectivity  

**Estimated time:** 30 minutes

---

## ✅ Prerequisites

Before starting Part 2, ensure you have:

✔️ **Completed** [Part 1: Fabric Intent Creation](part1-fabric-intent.md)  
✔️ Working underlay fabric with eBGP EVPN overlay  
✔️ All BGP sessions in **Established** state  
✔️ Pre-created **allocation pools** for:  
  - VNI (VXLAN Network Identifiers) - e.g., `vni-pool`
  - EVI (EVPN Instance) - e.g., `evi-pool`
  - Tunnel Index - e.g., `tunnel-index-pool`
✔️ **Client connections**:  
  - client1 connected to leaf1 ethernet-1/1 with VLAN 'null' (untagged) (IP: 172.17.0.1/24)
  - client2 connected to leaf2 ethernet-1/1 with VLAN 'null' (untagged) (IP: 172.17.0.2/24)
  - client3 connected to leaf3 ethernet-1/1 with VLAN 'null' (untagged) (IP: 172.17.0.3/24)
✔️ Access to EDA GUI

---

## 📚 L2 EVPN Concepts

### What is L2 EVPN?

**Layer 2 EVPN** creates a virtual bridge domain that spans multiple physical switches, allowing workloads on different leafs to communicate as if they were on the same physical Layer 2 network.

### Key Components

| Component | Description |
|-----------|-------------|
| **Bridge Domain** | A Layer 2 broadcast domain within a MAC-VRF network instance |
| **Bridge Interface** | Attachment point for workloads (subinterfaces with/without VLAN tagging) |
| **MAC-VRF** | Type of network instance for Layer 2 virtual routing and forwarding |
| **VNI** | VXLAN Network Identifier - identifies the Layer 2 segment in the overlay |
| **EVI** | EVPN Instance - identifies the EVPN service instance |
| **Tunnel Index** | Internal index for VXLAN tunnel interfaces |
| **VXLAN Interface** | Virtual tunnel endpoint for encapsulating Layer 2 frames |

### Service Architecture

```
┌─────────────────────────────────────────┐
│              Spine Layer                │
│       ┌─────────┐    ┌─────────┐        │
│       │ spine1  │────│ spine2  │        │
│       └────┬────┘    └────┬────┘        │
└────────────┼──────────────┼─────────────┘
             │              │
       ┌─────┴──────┬───────┴──────┐
       │            │              │    
  ┌────┴────┐  ┌────┴─────┐  ┌─────┴────┐ 
  │  leaf1  │  │  leaf2   │  │  leaf3   │ 
  └────┬────┘  └────┬─────┘  └─────┬────┘ 
       │            │              │
    ┌──┴──┐      ┌──┴──┐        ┌──┴──┐
    │ c1  │      │ c2  │        │ c3  │       ← Bridge Domain "l2vnet"
    │     │      │     │        │     │       ← VNI 200 (from vni-pool), EVI 100 (from evi-pool)
    │null │      │null │        │null │       ← VXLAN tunnel between leafs
    └─────┘      └─────┘        └─────┘
```

### Two Methods for L2 EVPN Service Creation

EDA provides two approaches:

#### **Method 1: Individual Components** (This Lab)
- Create Bridge Domain separately
- Create Bridge Interfaces separately
- More granular control
- Covered in this exercise

#### **Method 2: Virtual Networks** (Alternative)
- Create both Bridge Domains and Bridge Interfaces in one resource
- Simpler, conglomerate method
- Will be demonstrated in L3 EVPN service setup

---

## 🔧 Exercise 2: Create L2 EVPN Instance

In this exercise, we'll create a Layer 2 EVPN overlay service for client1, client2 and client3 using individual Bridge Domain and Bridge Interface components.

### Lab Topology

```
              ┌─────────┐  ┌─────────┐
              │ spine1  │  │ spine2  |  
              └────┬────┘  └────┬────┘
                   │            │
            ┌──────┴───────┐────┴───────┐
            │              │            │  
       ┌────┴────┐    ┌────┴────┐  ┌───-┴────┐ 
       │  leaf1  │    │  leaf2  │  │  leaf3  │ 
       └────┬────┘    └────┬────┘  └────┬────┘ 
            │              │            │
     ethernet-1/1.0 ethernet-1/1.0 ethernet-1/1.0
        untagged       untagged      untagged
            │              │            │
        ┌───┴───┐      ┌───┴───┐    ┌───┴───┐
        │client1│      │client2│    │client3│
        │ .0.1  │      │  0.2  │    │  0.3  │
        └───────┘      └───────┘    └───────┘
          
    Bridge Domain: l2vnet
    VNI: 200 (from vni-pool)
    EVI: 100 (from evi-pool)
    Tunnel Index: 500 (from tunnel-index-pool)
```

---

### Step 1: Create Bridge Domain

1. **Navigate to Bridge Domains**
   - In the EDA GUI, scroll down to **Virtual Networks** section in the left sidebar
   - Select **Bridge Domains**
   - Click the blue **Create** button

2. **Configure Bridge Domain Metadata**

   | Parameter | Value |
   |-----------|-------|
   | **Name** | `l2vnet` |
   | **Namespace** | `clab-dc-{GROUP_ID}-eda` (your datacenter namespace) |

3. **Configure Bridge Domain Specification**

   | Parameter | Value | Description |
   |-----------|-------|-------------|
   | **Type** | `EVPNVXLAN` | Enables EVPN-VXLAN for this bridge domain |
   | **VNI Allocation Pool** | `vni-pool` | Reference to VNI pool for allocations |
   | **EVI Allocation Pool** | `evi-pool` | Reference to EVI pool for allocations |
   | **Tunnel Index Allocation Pool** | `tunnel-index-pool` | Reference to tunnel index pool |

   > **Note on Allocation Pools:** EDA supports both automatic pool-based allocation (preferred for automation) and manual index specification. Using pools ensures no conflicts and simplifies management.

4. **Review Additional Settings**

   The Bridge Domain specification includes advanced settings:
   - **Export Target / Import Target:** Auto-generated as `target:1:<evi>`
   - **MAC Limit:** Maximum number of MAC entries (optional)
   - **MAC Aging:** Configurable aging time (default: 300 seconds)
   - **MAC Duplication Detection:** Can be enabled with configurable actions

5. **Add to Transaction**
   - Click **Create** or **Add to Transaction**
   - Do NOT commit yet - we'll add Bridge Interfaces first

---

### Step 2: Create Bridge Interfaces

We need to create two Bridge Interfaces to connect client1, client2 and client3 to the Bridge Domain.

#### Bridge Interface for Client1

1. **Navigate to Bridge Interfaces**
   - Under **Virtual Networks** resources, select **Bridge Interfaces**
   - Click **Create**

2. **Configure client1 Bridge Interface Metadata**

   | Parameter | Value |
   |-----------|-------|
   | **Name** | `client1` |
   | **Namespace** | `clab-dc-{GROUP_ID}-eda` |

3. **Configure client1 Bridge Interface Specification**

   | Parameter | Value | Description |
   |-----------|-------|-------------|
   | **Bridge Domain** | `l2vnet` | Reference to the Bridge Domain created above |
   | **VLAN ID** | `null` | VLAN tag for this subinterface |
   | **Interface** | `leaf1-ethernet-1-1` | Physical interface reference |

   > **Interface Naming:** Use the exact interface resource name from your topology. Format is typically `<node>-<interface>`.

4. **Optional Settings**
   - **Description:** `interface to c1`
   - **L2 MTU:** Leave default or specify if needed
   - **MAC Duplication Detection Action:** Override BD settings if needed

5. **Add to Transaction**
   - Click **Create** or **Add to Transaction**

#### Bridge Interface for Client2

1. **Create Second Bridge Interface**
   - Click **Create** again in Bridge Interfaces view

2. **Configure client2 Bridge Interface Metadata**

   | Parameter | Value |
   |-----------|-------|
   | **Name** | `client2` |
   | **Namespace** | `clab-dc-{GROUP_ID}-eda` |

3. **Configure client2 Bridge Interface Specification**

   | Parameter | Value |
   |-----------|-------|
   | **Bridge Domain** | `l2vnet` |
   | **VLAN ID** | `null` |
   | **Interface** | `leaf2-ethernet-1-1` |

4. **Add to Transaction**
   - Click **Create** or **Add to Transaction**

#### Bridge Interface for Client3

1. **Create Second Bridge Interface**
   - Click **Create** again in Bridge Interfaces view

2. **Configure client3 Bridge Interface Metadata**

   | Parameter | Value |
   |-----------|-------|
   | **Name** | `client3` |
   | **Namespace** | `clab-dc-{GROUP_ID}-eda` |

3. **Configure client3 Bridge Interface Specification**

   | Parameter | Value |
   |-----------|-------|
   | **Bridge Domain** | `l2vnet` |
   | **VLAN ID** | `null` |
   | **Interface** | `leaf3-ethernet-1-1` |

4. **Add to Transaction**
   - Click **Create** or **Add to Transaction**
  
---

### Step 3: Review and Commit

1. **Open Transaction Basket**
   - Navigate to your active transaction
   - You should see 3 resources ready to commit:
     - 1 Bridge Domain (`l2vnet`)
     - 2 Bridge Interfaces (`client1`, `client2`, `client3`)

2. **Add Commit Message**
   ```
   Create L2 EVPN service for client1, client2 and client3
   ```

3. **Run Dry-Run (Optional but Recommended)**
   - Click **Dry-run** to preview changes
   - Review the configuration that will be generated on leaf1, leaf2 and leaf3
   - Expected changes:
     - Network-instance `l2vnet` of type `mac-vrf`
     - Subinterface `ethernet-1/1.0` with VLAN untagged
     - VXLAN interface with allocated VNI
     - BGP EVPN configuration with allocated EVI

4. **Commit the Transaction**
   - Click **Commit**
   - Wait for successful completion
   - EDA will automatically:
     - Validate the design
     - Generate configuration for leaf1, leaf2 and leaf3
     - Push config to the network devices

---

## ✅ Exercise 3: Verify L2 EVPN Service

Now let's verify that the L2 EVPN service is operational.

---

### Step 1: View Bridge Domain Summary

1. **Navigate to Bridge Domains Summary**
   - In EDA GUI, go to **Virtual Networks → Bridge Domains**
   - Click on the **Summary** tab

2. **Check Bridge Domain Status**

   You should see:
   - **Bridge Domain Deployment Distribution:**
     - Number of Bridge Domains deployed
     - Status: `L2vnet is 'up'`
   - **Bridge Table Entries:** Initially empty until traffic flows
   - **Operational State:** up

3. **Drill Down to l2vnet Details**
   - Click on `l2vnet` then information or view to view details
   - Verify:
     - Deployed nodes: leaf1, leaf2, leaf3
     - VNI allocation from pool
     - EVI allocation from pool
     - Tunnel Index from pool
     - Associated bridge interfaces

---

### Step 2: Test End-to-End Connectivity

1. **Access client2**
   ```bash
   # SSH or console to client2
   sudo docker exec -it clab-dc-{GROUP_ID}-eda-client2 sh
   ```

2. **Verify Interface Configuration**
   ```bash
   client2:~# ifconfig eth1
   ```

   **Expected Output:**
   ```
   eth1      Link encap:Ethernet  HWaddr AA:C1:AB:6F:41:45
             inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.255.0
             inet6 addr: fe80::a8c1:abff:fe6f:4145/64 Scope:Link
             UP BROADCAST RUNNING MULTICAST  MTU:9500  Metric:1
             RX packets:1 errors:0 dropped:0 overruns:0 frame:0
             TX packets:111 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:1000
             RX bytes:56 (56.0 B)  TX bytes:8026 (7.8 KiB)
   ```

   ✅ Client2 has IP 172.17.0.2/24

3. **Ping Client1**
   ```bash
   client2:~# ping 172.17.0.1
   ```

   **Expected Output:**
   ```
   PING 172.17.0.1 (172.17.0.1): 56(84) bytes of data.
   64 bytes from 172.17.0.1: icmp_seq=1 ttl=64 time=9.72 ms
   64 bytes from 172.17.0.1: icmp_seq=2 ttl=64 time=1.39 ms
   64 bytes from 172.17.0.1: icmp_seq=3 ttl=64 time=0.740 ms
   64 bytes from 172.17.0.1: icmp_seq=4 ttl=64 time=0.784 ms
   64 bytes from 172.17.0.1: icmp_seq=5 ttl=64 time=0.631 ms
   ^C
   --- 172.17.0.1 ping statistics ---
   5 packets transmitted, 5 packets received, 0% packet loss
   round-trip min/avg/max = 0.824/1.164/2.102 ms
   ```

   ✅ **Success!** Layer 2 connectivity is working across the EVPN-VXLAN overlay.

---

### Step 3: Verify Device Configuration

SSH to leaf1 to examine the EDA-generated configuration.

#### Check Network Instance Configuration

```bash
ssh admin@leaf1

--{ running }--[ ]--
A:admin@leaf1# info network-instance l2vnet
```

**Expected Configuration:**
```
network-instance l2vnet {
    !!! EDA Source CRs: services.eda.nokia.com/v1/BridgeInterface/client1
    type mac-vrf
    admin-state enable
    description l2vnet
    interface ethernet-1/1.4097 {
        !!! EDA Source CRs: services.eda.nokia.com/v1/BridgeInterface/client1
    }
    vxlan-interface vxlan0.500 {
    }
    protocols {
        bgp-evpn {
            bgp-instance 1 {
                vxlan-interface vxlan0.500
                evi 100
                ecmp 8
            }
        }
        bgp-vpn {
            bgp-instance 1 {
                route-target {
                    export-rt target:1:100
                    import-rt target:1:100
                }
            }
        }
    }
    bridge-table {
        mac-learning {
            admin-state enable
            aging {
                admin-state enable
                age-time 300
            }
        }
    }
}
```

**Key Elements:**
- ✅ Network instance type: `mac-vrf`
- ✅ Local bridge interface: `ethernet-1/1.4097` connected to client1
- ✅ VXLAN interface: `vxlan0.500` for overlay connectivity
- ✅ EVI: `100` (allocated from pool)
- ✅ Route targets: `target:1:100` for import/export
- ✅ MAC learning enabled with 300s aging

#### Check VXLAN Tunnel Configuration

```bash
--{ running }--[ ]--
A:admin@leaf1# info tunnel-interface vxlan0 vxlan-interface 500
```

**Expected Configuration:**
```
        type bridged
        ingress {
            vni 200
        }
        egress {
            source-ip use-system-ipv4-address
        }
```

**Key Elements:**
- ✅ VNI: `200` (allocated from vni-pool)
- ✅ Type: `bridged` (Layer 2 service)
- ✅ Source IP: Uses system IPv4 address (loopback) as VTEP

---

### Step 4: Check MAC Learning

Verify that MAC addresses are being learned across the EVPN overlay.

```bash
--{ running }--[ ]--
A:admin@leaf1# show network-instance l2vnet bridge-table mac-table all
```

**Expected Output:**
```
--------------------------------------------------------------------------------------------------------------------------------------
Mac-table of network instance l2vnet
--------------------------------------------------------------------------------------------------------------------------------------
+-------------------+---------------------------------+-----------+----------+--------+-------+---------------------------------+
|      Address      |           Destination           |   Dest    |   Type   | Active | Aging |           Last Update           |
|                   |                                 |   Index   |          |        |       |                                 |
+===================+=================================+===========+==========+========+=======+=================================+
| AA:C1:AB:64:CD:5B | ethernet-1/1.4097               | 9         | learnt   | true   | 300   | 2025-10-07T14:33:11.000Z        |
| AA:C1:AB:DA:1E:53 | vxlan-interface:vxlan0.500      | 834435197 | evpn     | true   | N/A   | 2025-10-07T14:33:10.000Z        |
|                   | vtep:11.0.0.2 vni:200           | 0         |          |        |       |                                 |
+-------------------+---------------------------------+-----------+----------+--------+-------+---------------------------------+
Total Irb Macs                 :    0 Total    0 Active
Total Static Macs              :    0 Total    0 Active
Total Duplicate Macs           :    0 Total    0 Active
Total Learnt Macs              :    1 Total    1 Active
Total Evpn Macs                :    1 Total    1 Active
Total Evpn static Macs         :    0 Total    0 Active
Total Irb anycast Macs         :    0 Total    0 Active
Total Proxy Antispoof Macs     :    0 Total    0 Active
Total Reserved Macs            :    0 Total    0 Active
Total Eth-cfm Macs             :    0 Total    0 Active
Total Irb Vrrps                :    0 Total    0 Active
```

**MAC Table Analysis:**

| MAC Address | Destination | Type | Meaning |
|-------------|-------------|------|---------|
| `AA:C1:AB:DA:1E:53` | `vxlan-interface:vxlan0.500 vtep:11.0.0.2 vni:200` | `evpn` | Remote MAC (client2) learned via EVPN from leaf2 (11.0.0.2) |
| `AA:C1:AB:64:CD:5B` | `ethernet-1/1.4097` | `learnt` | Local MAC (client1) learned on local interface |

✅ **VXLAN Tunnel Established:** Notice the VXLAN tunnel with VNI 200 to leaf2 (VTEP 11.0.0.2) to reach client2.

---

## 🎯 Alternative Method: Virtual Networks

While this lab used the **individual components method** (separate Bridge Domain and Bridge Interface creation), EDA also offers a **conglomerate method** using the **Virtual Networks** resource.

### Virtual Networks Approach

The Virtual Networks resource allows you to:
- Define both Bridge Domains and Bridge Interfaces in a single configuration
- Simplify service deployment with less granular control
- Useful for standardized service templates

### When to Use Each Method

| Method | Use Case |
|--------|----------|
| **Individual Components** | Fine-grained control, complex multi-tenant scenarios, custom configurations |
| **Virtual Networks** | Rapid deployment, standardized services, simpler topologies |

> **Note:** The Virtual Networks method will be introduced in the L3 EVPN service setup (future lab extension).

---

## 🛠️ Troubleshooting & Tips

<details>
<summary><b>Bridge Domain not appearing in EDA GUI</b></summary>

**Possible causes:**
- Transaction not committed
- Namespace mismatch
- Validation errors during commit

**Solution:**
1. Check transaction status - ensure commit was successful
2. Verify namespace matches across Bridge Domain and Bridge Interfaces
3. Review transaction logs for any validation failures
4. Refresh the GUI view

</details>

<details>
<summary><b>Bridge Interface creation fails</b></summary>

**Possible causes:**
- Bridge Domain doesn't exist yet
- Invalid interface reference
- VLAN ID already in use

**Solution:**
1. Ensure Bridge Domain is committed before creating Bridge Interfaces
2. Verify interface name matches topology exactly (e.g., `leaf1-ethernet-1-1`)
3. Check for VLAN ID conflicts with existing services
4. Review interface availability on the target node

</details>

<details>
<summary><b>Clients cannot ping each other</b></summary>

**Possible causes:**
- VLAN mismatch on clients
- Bridge Interface not attached to correct physical interface
- VXLAN tunnel not established
- Underlay BGP sessions down

**Solution:**
1. Verify both clients are untagged: `ifconfig eth1`
2. Check Bridge Interface configuration on both leafs
3. Verify VXLAN tunnel: `show tunnel-interface vxlan0 vxlan-interface * detail`
4. Confirm underlay BGP: `show network-instance default protocols bgp neighbor`
5. Check EVPN routes: `show network-instance default protocols bgp routes evpn route-type 3`

</details>

<details>
<summary><b>MAC addresses not learning</b></summary>

**Possible causes:**
- MAC learning disabled
- Bridge table full (MAC limit reached)
- EVPN Type-2 routes not being advertised
- Client not sending traffic

**Solution:**
1. Verify MAC learning is enabled in bridge-table config
2. Check MAC table: `show network-instance l2vnet bridge-table mac-table all`
3. Generate traffic from clients (ping or arp)
4. Verify EVPN Type-2 routes: `show network-instance default protocols bgp routes evpn route-type 2`
5. Check for MAC duplication detection blocking learning

</details>

<details>
<summary><b>VNI/EVI allocation failures</b></summary>

**Possible causes:**
- Allocation pool exhausted
- Pool not accessible from namespace
- Pool allocation range conflicts

**Solution:**
1. Check pool utilization: Navigate to allocation pools in EDA GUI
2. Verify pool has available resources
3. Ensure pool is in correct namespace or globally accessible
4. Review pool range definitions for overlaps
5. Consider expanding pool range if exhausted

</details>

<details>
<summary><b>Configuration not pushed to devices</b></summary>

**Possible causes:**
- Transaction dry-run only (not committed)
- Node connectivity issues
- Device authentication failure
- Commit transaction timed out

**Solution:**
1. Verify transaction was **committed**, not just dry-run
2. Check device reachability from EDA
3. Verify device credentials in EDA
4. Review transaction logs for push failures
5. Check device connectivity: `ping <leaf-mgmt-ip>`

</details>

<details>
<summary><b>EVPN routes not being exchanged</b></summary>

**Possible causes:**
- BGP EVPN address-family not configured
- Route target mismatch
- BGP session not established
- EVPN not enabled in overlay protocol

**Solution:**
1. Verify overlay protocol is EBGP in fabric intent
2. Check BGP EVPN sessions: `show network-instance default protocols bgp neighbor | grep evpn`
3. Verify route targets match: should be `target:1:<evi>`
4. Check EVPN configuration in network-instance: `info network-instance l2vnet protocols bgp-evpn`

</details>

### 💡 Best Practices

1. **Always use allocation pools** for VNI, EVI, and Tunnel Index to avoid manual conflicts
2. **Use descriptive names** for Bridge Domains and Interfaces (e.g., `customer-a-untagged`)
3. **Document VLAN assignments** to track which VLANs are used for which services
4. **Test with dry-run first** before committing changes to production
5. **Verify end-to-end connectivity** after each service deployment
6. **Monitor MAC table growth** to detect potential MAC address exhaustion
7. **Use consistent namespaces** across related resources (Bridge Domain, Bridge Interfaces)
8. **Label your resources** for easier filtering and management in large deployments

---

## 📝 Key Takeaways

### What You've Accomplished

✅ **Created a Bridge Domain** (`l2vnet`) with EVPN-VXLAN type  
✅ **Configured Bridge Interfaces** for two clients on different leaf switches  
✅ **Utilized allocation pools** for automatic VNI, EVI, and Tunnel Index assignment  
✅ **Verified EVPN operation** through MAC learning and VXLAN tunnel establishment  
✅ **Tested end-to-end connectivity** between clients across the overlay  

### Understanding the EDA-Generated Configuration

EDA automatically created:

1. **Network Instance (MAC-VRF)**
   - Type: `mac-vrf` for Layer 2 bridging
   - Bridge interfaces for local client attachment
   - VXLAN interfaces for overlay connectivity

2. **EVPN Configuration**
   - BGP EVPN instance with allocated EVI
   - Route targets for route distribution control
   - Type-2 (MAC/IP) and Type-3 (IMET) route advertisements

3. **VXLAN Tunnels**
   - Ingress VNI mapping for traffic identification
   - Source IP from system loopback (VTEP address)
   - Automatic tunnel establishment to remote VTEPs

4. **Bridge Table**
   - MAC learning configuration
   - Aging timers
   - MAC duplication detection (optional)

### Service Flow Summary

```
Client1 (VLAN null / untagged)
    ↓
ethernet-1/1.4097 on leaf1
    ↓
Bridge Domain "l2vnet"
    ↓
VXLAN tunnel (VNI 200)
    ↓
EVPN control plane (EVI 100, RT target:1:100)
    ↓
Spine layer (Route Reflector)
    ↓
VXLAN tunnel (VNI 200)
    ↓
Bridge Domain "l2vnet" on leaf2
    ↓
ethernet-1/1.4097 on leaf2
    ↓
Client2 (VLAN null / untagged)
```

---

## 🎯 What's Next?

Congratulations! You've successfully deployed a Layer 2 EVPN overlay service using EDA.

### Next Steps in Your Learning Journey

1. **Expand the Service**
   - Add more clients to the same Bridge Domain
   - Create additional Bridge Domains for different VLANs
   - Implement multi-tenancy with separate Bridge Domains

2. **Layer 3 Services** (Future Lab)
   - Create IP-VRF instances for inter-subnet routing
   - Configure IRB (Integrated Routing and Bridging) interfaces
   - Implement EVPN Type-5 routes for IP prefix advertisement
   - Use the Virtual Networks conglomerate method

3. **Advanced Features** (Future Lab)
   - EVPN Multi-homing (LAG across multiple leafs)
   - EVPN Route Filtering and Policy
   - MAC Mobility and Mass Withdrawal
   - Silent Host Detection

4. **Continue to Part 3**
   - 🔍 **[Part 3: Deviations & EQL](part3-deviations-eql.md)** - Monitor configuration drift and query network state

---

## 📚 Additional Resources

### Documentation
- [Nokia EDA Documentation](https://docs.eda.dev/)
- [SR Linux Documentation](https://documentation.nokia.com/srlinux/)

### Related Exercises
- **Exercise 1:** Fabric Intent Creation (Part 1)
- **Exercise 2:** Create L2 EVPN Instance (This Lab)
- **Exercise 3:** Verify L2 EVPN Service (This Lab)
- **Exercise 4:** Create L3 EVPN Instance (Future)

### Command Reference

**EDA GUI Navigation:**
```
Virtual Networks → Bridge Domains → Create
Virtual Networks → Bridge Interfaces → Create
```

**SR Linux Verification Commands:**
```bash
# Network instance configuration
info network-instance <name>

# Bridge table
show network-instance <name> bridge-table mac-table all

# VXLAN tunnels
show tunnel-interface vxlan0 vxlan-interface * detail

# EVPN routes
show network-instance default protocols bgp routes evpn route-type 2
show network-instance default protocols bgp routes evpn route-type 3

# Interface status
show interface ethernet-1/1.4097
```

---

## 🏁 Lab Completion Summary

**This concludes Exercises 2 and 3 of the SGNOG12 EDA Lab!**

You have successfully:
- Created individual Bridge Domain and Bridge Interface components
- Deployed an L2 EVPN service across a multi-leaf fabric
- Verified EVPN-VXLAN operation and connectivity
- Understood EDA's automatic configuration generation
- Learned verification techniques for overlay services

**Total Time:** ~45 minutes

---

**Navigation:**

- [Back to Part 1: Fabric Intent Creation](part1-fabric-intent.md)
- [Continue to Part 3: Deviations & EQL](part3-deviations-eql.md)
- [Return to Main Lab Guide](README.md)

---

**Ready for advanced monitoring and querying?** Continue to [Part 3: Deviations & EQL](part3-deviations-eql.md)
