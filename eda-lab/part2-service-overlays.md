# 🔄 Part 2: Service Overlays

> **Building EVPN-VXLAN Services on Your EDA Fabric**

Now that your underlay fabric is operational, this guide walks you through creating **service overlays** using EVPN-VXLAN to enable Layer 2 and Layer 3 connectivity across your datacenter fabric.

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [EVPN-VXLAN Concepts](#-evpn-vxlan-concepts)
4. [Step-by-Step Guide](#-step-by-step-guide)
   - [Step 1: Create MAC-VRF (Layer 2 Service)](#step-1-create-mac-vrf-layer-2-service)
   - [Step 2: Configure Bridge Domains](#step-2-configure-bridge-domains)
   - [Step 3: Create IP-VRF (Layer 3 Service)](#step-3-create-ip-vrf-layer-3-service)
   - [Step 4: Configure IRB Interfaces](#step-4-configure-irb-interfaces)
   - [Step 5: Verify EVPN Routes](#step-5-verify-evpn-routes)
   - [Step 6: End-to-End Service Verification](#step-6-end-to-end-service-verification)
5. [Multi-Tenancy](#-multi-tenancy)
6. [Troubleshooting & Tips](#-troubleshooting--tips)
7. [What's Next?](#-whats-next)

---

## 🎯 Overview

In this lab, you will:

- ✅ Understand EVPN-VXLAN overlay architecture
- ✅ Create Layer 2 services using MAC-VRF
- ✅ Configure bridge domains and VXLAN tunnels
- ✅ Create Layer 3 services using IP-VRF
- ✅ Implement inter-subnet routing with IRB
- ✅ Verify EVPN route advertisements
- ✅ Test end-to-end connectivity

**Estimated time:** 60 minutes

---

## ✅ Prerequisites

Before starting Part 2, ensure you have:

- ✔️ **Completed** [Part 1: Fabric Intent Creation](part1-fabric-intent.md)
- ✔️ Working underlay fabric with eBGP EVPN overlay
- ✔️ All BGP sessions in **Established** state
- ✔️ Pre-created allocation pools for:
  - VLAN IDs
  - VNI (VXLAN Network Identifiers)
  - Subnet pools for overlay services
- ✔️ Access to EDA GUI and CLI

---

## 📚 EVPN-VXLAN Concepts

### What is EVPN-VXLAN?

**EVPN** (Ethernet VPN) is a BGP-based control plane that advertises MAC addresses and IP routes across the fabric.

**VXLAN** (Virtual Extensible LAN) is a data plane encapsulation protocol that tunnels Layer 2 frames over Layer 3 networks.

### Key Components

| Component | Description |
|-----------|-------------|
| **MAC-VRF** | Layer 2 virtual routing and forwarding instance |
| **IP-VRF** | Layer 3 virtual routing and forwarding instance |
| **Bridge Domain** | Layer 2 broadcast domain within a MAC-VRF |
| **VNI** | VXLAN Network Identifier - like a VLAN ID for overlays |
| **IRB** | Integrated Routing and Bridging - enables L2/L3 gateway |
| **RT/RD** | Route Target/Route Distinguisher for BGP route isolation |

### EVPN Route Types

- **Type 2:** MAC/IP Advertisement
- **Type 3:** Inclusive Multicast Ethernet Tag (IMET)
- **Type 5:** IP Prefix Route

---

## 📖 Step-by-Step Guide

### Step 1: Create MAC-VRF (Layer 2 Service)

Navigate to **Network Instances → Create** in the EDA GUI.

#### Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | `customer-a-l2` | MAC-VRF instance name |
| **Type** | `mac-vrf` | Layer 2 instance type |
| **VXLAN Interface** | `vxlan0` | VXLAN tunnel interface |
| **EVI** | `100` | EVPN Instance identifier |
| **Node Selector** | `eda.nokia.com/role=leaf` | Apply to all leaf switches |

#### Using Intent-Based Configuration

```yaml
# Example: MAC-VRF Intent (pseudocode)
apiVersion: eda.nokia.com/v1
kind: MacVrf
metadata:
  name: customer-a-l2
spec:
  evi: 100
  nodeSelector:
    matchLabels:
      eda.nokia.com/role: leaf
  vxlanInterface: vxlan0
```

> **💡 Tip:** Use EDA's allocation pools to automatically assign VNIs and avoid conflicts.

---

### Step 2: Configure Bridge Domains

Bridge domains define Layer 2 broadcast domains within your MAC-VRF.

#### Create Bridge Domain

| Parameter | Value |
|-----------|-------|
| **Bridge Domain ID** | `10` |
| **VLAN** | `100` |
| **VNI** | `10100` |
| **Associated Interfaces** | `ethernet-1/10` |

#### Transaction Steps

1. ➕ Add bridge domain configuration to transaction
2. ✍️ Add commit message: "Add customer-a VLAN 100"
3. 🔍 Run **Dry-run** to preview
4. ✅ **Commit** the transaction

#### Verification on SR Linux

```bash
# View MAC-VRF configuration
info network-instance customer-a-l2

# Check bridge table
show network-instance customer-a-l2 bridge-table mac-table all

# Verify VXLAN tunnel endpoints (VTEPs)
show tunnel-interface vxlan0 vxlan-interface * detail
```

**Expected output:**
- Bridge domain with VLAN 100 mapped to VNI 10100
- VXLAN tunnels to other leaf switches
- EVPN Type-3 (IMET) routes advertising the VNI

---

### Step 3: Create IP-VRF (Layer 3 Service)

For inter-subnet routing, create an IP-VRF instance.

#### Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Name** | `customer-a-l3` | IP-VRF instance name |
| **Type** | `ip-vrf` | Layer 3 instance type |
| **Route Distinguisher** | `auto` | Auto-generated RD |
| **Route Target** | `target:65000:1000` | BGP route target |
| **Node Selector** | `eda.nokia.com/role=leaf` | Apply to all leaf switches |

---

### Step 4: Configure IRB Interfaces

IRB (Integrated Routing and Bridging) provides the Layer 3 gateway for your Layer 2 segments.

#### Create IRB Interface

| Parameter | Value |
|-----------|-------|
| **Interface** | `irb0.100` |
| **IPv4 Address** | `10.1.1.1/24` (from allocation pool) |
| **Associated MAC-VRF** | `customer-a-l2` |
| **Bridge Domain** | `10` |
| **IP-VRF** | `customer-a-l3` |

#### Anycast Gateway

For active-active gateways across multiple leafs:

- Use the **same IP** on all leaf switches
- Use a **virtual MAC address** (auto-generated or specified)

```bash
# Example anycast gateway config
/interface irb0
  subinterface 100
    ipv4 address 10.1.1.1/24
    anycast-gw
      virtual-router-id 1
```

---

### Step 5: Verify EVPN Routes

Check that EVPN routes are being advertised correctly across the fabric.

#### View EVPN Route Types

```bash
# Type 2: MAC/IP routes
show network-instance default protocols bgp routes evpn route-type 2 detail

# Type 3: IMET routes (multicast)
show network-instance default protocols bgp routes evpn route-type 3

# Type 5: IP Prefix routes
show network-instance default protocols bgp routes evpn route-type 5
```

#### Expected EVPN Advertisements

| Route Type | What to Verify |
|------------|----------------|
| **Type 2** | MAC addresses learned in bridge domains |
| **Type 3** | All leaf VTEPs advertising the VNI |
| **Type 5** | IP prefixes from IP-VRF (if symmetric IRB) |

---

### Step 6: End-to-End Service Verification

#### Connectivity Tests

From a host connected to `leaf1` VLAN 100:

```bash
# Test Layer 2 connectivity to host on leaf2 VLAN 100
ping <host-on-leaf2>

# Test Layer 3 connectivity through IRB gateway
ping 10.1.1.1  # IRB interface

# Test cross-subnet routing
ping 10.1.2.100  # Host in different subnet
```

#### MAC Learning Verification

```bash
# On leaf1: Check if MACs from leaf2 are learned via EVPN
show network-instance customer-a-l2 bridge-table mac-table all

# Look for 'evpn' in the Type column
```

#### VXLAN Tunnel Statistics

```bash
# Check VXLAN encap/decap counters
show tunnel-interface vxlan0 vxlan-interface * statistics
```

---

## 🏢 Multi-Tenancy

### Isolation Strategies

EDA supports multiple tenancy models:

#### 1. **VRF-based Isolation**

Each tenant gets dedicated MAC-VRF and IP-VRF instances:

```
Tenant A: customer-a-l2 (MAC-VRF) + customer-a-l3 (IP-VRF)
Tenant B: customer-b-l2 (MAC-VRF) + customer-b-l3 (IP-VRF)
```

#### 2. **VLAN-based Isolation**

Multiple bridge domains within shared VRF:

```
Shared MAC-VRF:
  - Bridge Domain 10 (VLAN 100, VNI 10100) → Tenant A
  - Bridge Domain 20 (VLAN 200, VNI 10200) → Tenant B
```

#### 3. **Route Target Isolation**

Use BGP route targets to control route import/export:

```yaml
Tenant A RT: target:65000:1000
Tenant B RT: target:65000:2000
```

### Using EDA for Multi-Tenancy

Create tenant-specific intents with selectors:

```yaml
# Tenant A selector
nodeSelector:
  matchLabels:
    eda.nokia.com/tenant: customer-a
    eda.nokia.com/role: leaf
```

---

## 🛠️ Troubleshooting & Tips

<details>
<summary><b>❓ EVPN routes not being advertised</b></summary>

**Possible causes:**
- BGP EVPN session not established
- Route target misconfiguration
- VNI not configured on both ends

**Solution:**
1. Verify BGP EVPN session: `show network-instance default protocols bgp neighbor`
2. Check route target config in IP-VRF
3. Verify VNI consistency across all leafs

</details>

<details>
<summary><b>❓ MAC addresses not learning across fabric</b></summary>

**Possible causes:**
- VXLAN tunnel not established
- Bridge domain misconfiguration
- Type-3 routes not being exchanged

**Solution:**
1. Check VXLAN interface: `show tunnel-interface vxlan0`
2. Verify Type-3 routes: `show network-instance default protocols bgp routes evpn route-type 3`
3. Review bridge domain config

</details>

<details>
<summary><b>❓ Inter-subnet routing not working</b></summary>

**Possible causes:**
- IRB interface not configured in IP-VRF
- Missing Type-5 route advertisements
- Route target import/export issues

**Solution:**
1. Verify IRB in IP-VRF: `info network-instance customer-a-l3`
2. Check Type-5 routes: `show network-instance default protocols bgp routes evpn route-type 5`
3. Review route target configuration

</details>

<details>
<summary><b>❓ High VXLAN encapsulation errors</b></summary>

**Possible causes:**
- MTU misconfiguration
- Underlay routing issues
- Fragmentation

**Solution:**
1. Verify MTU on underlay interfaces (recommend 9100+ for VXLAN overhead)
2. Check underlay routing: `show network-instance default route-table`
3. Review interface statistics for errors

</details>

---

## 🎓 What's Next?

Excellent work! You've successfully deployed EVPN-VXLAN overlay services on your EDA fabric.

**Next steps:**

- 🔍 **[Part 3: Deviations & EQL](part3-deviations-eql.md)** - Monitor configuration drift and query network state
- 🔙 **[Back to Part 1](part1-fabric-intent.md)** - Review fabric underlay concepts
- 🏠 **[Main Lab Guide](README.md)** - Overview of all lab parts

---

## 📚 Additional Resources

- [EVPN-VXLAN Architecture Guide](https://learn.srlinux.dev/)
- [SR Linux Network Instance Configuration](https://documentation.nokia.com/srlinux/)
- [Nokia EDA Service Intent Reference](https://network.developer.nokia.com/)

---

**Ready for Part 3?** 🎯 Continue to [Deviations & EQL](part3-deviations-eql.md)
