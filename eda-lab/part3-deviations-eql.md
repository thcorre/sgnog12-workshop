# 🔍 Part 3: Deviations & EQL (EDA Query Language)

> **Advanced Network Monitoring and Configuration Management with EDA**

This guide explores EDA's powerful capabilities for **detecting configuration deviations** and **querying network state** using EQL (EDA Query Language) to gain deep insights into your infrastructure.

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [Understanding Deviations](#-understanding-deviations)
4. [Exercise 7.2: Configuration Deviations](#-exercise-72-configuration-deviations)
   - [Step 1: Create a Test Deviation](#step-1-create-a-test-deviation)
   - [Step 2: View Deviation in EDA GUI](#step-2-view-deviation-in-eda-gui)
   - [Step 3: Analyze Deviation Details](#step-3-analyze-deviation-details)
   - [Step 4: Accept a Deviation](#step-4-accept-a-deviation)
   - [Step 5: Clear Accepted Deviation](#step-5-clear-accepted-deviation)
   - [Step 6: Reject a Deviation](#step-6-reject-a-deviation)
   - [Step 7: Verify Remediation](#step-7-verify-remediation)
5. [Exercise 7.3: EQL Queries](#-exercise-73-eql-queries)
   - [Understanding EQL Syntax](#understanding-eql-syntax)
   - [Example Queries](#example-queries)
6. [Troubleshooting & Tips](#-troubleshooting--tips)
7. [Lab Summary](#-lab-summary)

---

## 🎯 Overview

In this lab, you will:

- ✅ Understand what configuration deviations are and why they matter
- ✅ Detect and analyze deviations in your EDA-managed fabric
- ✅ Learn to accept or reject deviations
- ✅ Master EQL syntax for querying network state
- ✅ Build practical queries for day-to-day operations
- ✅ Extract operational insights from your network

**Estimated time:** 45 minutes

---

## ✅ Prerequisites

Before starting Part 3, ensure you have:

- ✔️ **Completed** [Part 1: Fabric Intent Creation](part1-fabric-intent.md)
- ✔️ **Completed** [Part 2: Service Overlays](part2-service-overlays.md)
- ✔️ Active fabric with committed intents
- ✔️ L3 EVPN service deployed (with IRB interfaces)
- ✔️ Access to EDA GUI
- ✔️ SSH access to leaf switches

---

## 📚 Understanding Deviations

### What is a Configuration Deviation?

A **deviation** occurs when the actual configuration on a device differs from the **intended state** defined in EDA.

#### Common Deviation Causes

| Cause | Example |
|-------|---------|
| **Manual Changes** | Operator modifies config via CLI outside EDA |
| **External Automation** | Scripts change configuration bypassing EDA |
| **Operational Actions** | Temporary troubleshooting changes |
| **Device Issues** | Configuration not applied correctly |

### Why Deviations Matter

- ❌ **Configuration Drift:** Network state diverges from intended design
- ❌ **Service Impact:** Unexpected behavior, connectivity loss
- ❌ **Compliance Violations:** Audit and policy enforcement issues
- ❌ **Operational Risk:** Inconsistent network state

### EDA's Deviation Detection

EDA continuously monitors device state and compares it against committed intents:

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  EDA Intent │ ───> │ Expected     │ ───> │ Deviation   │
│  (Desired)  │      │ Config       │      │ Detection   │
└─────────────┘      └──────────────┘      └─────────────┘
                              │                     │
                              ▼                     ▼
                     ┌──────────────┐      ┌─────────────┐
                     │ Actual       │ ───> │ Alarm/      │
                     │ Device State │      │ Alert       │
                     └──────────────┘      └─────────────┘
```

---

## 🔧 Exercise 7.2: Configuration Deviations

In this exercise, we'll intentionally create a deviation to understand how EDA detects and handles configuration drift.

### Lab Scenario

- We'll disable an IRB interface on leaf1 (l1)
- This will cause connectivity issues between clients
- EDA will detect the deviation and raise alarms
- We'll explore options to accept or reject the deviation

---

### Step 1: Create a Test Deviation

1. **SSH to leaf1 (l1)**
   ```bash
   ssh admin@l1
   ```

2. **Disable IRB Subinterface**
   ```bash
   --{ + running }--[ ]--
   A:admin@l1# enter candidate
   
   --{ + candidate shared default }--[ ]--
   A:admin@l1# interface irb0 subinterface 1
   
   --{ + candidate shared default }--[ interface irb0 subinterface 1 ]--
   A:admin@l1# admin-state disable
   
   --{ +* candidate shared default }--[ interface irb0 subinterface 1 ]--
   A:admin@l1# commit now
   All changes have been committed. Leaving candidate mode.
   ```

   > **What happened?** We manually disabled the IRB interface that EDA created. This is a deviation because EDA expects this interface to be enabled.

---

### Step 2: View Deviation in EDA GUI

1. **Check for Alarms**
   - Navigate to **Alarms** in the EDA GUI
   - You should see alarms generated immediately after the commit:
     - `RouterDegraded` (Major severity)
     - `IRBInterfaceDown-irb-compute` (Major severity)

   | Severity | Type | Occurrences | Name | Last Changed |
   |----------|------|-------------|------|--------------|
   | Major | RouterDegraded | 2 | RouterDegraded-router | Wed Jun 18 2025, 14:29:35 EDT |
   | Major | IRBInterfaceDown | 2 | IRBInterfaceDown-irb-compute | Wed Jun 18 2025, 14:29:35 EDT |

2. **Test Connectivity Impact**
   - SSH to client c3
   - Try to ping c1 (should fail due to disabled IRB):
   
   ```bash
   c3/ # ping 172.29.20.11
   PING 172.29.20.11 (172.29.20.11): 56 data bytes
   ^C
   --- 172.29.20.11 ping statistics ---
   3 packets transmitted, 0 packets received, 100% packet loss
   ```
   
   - Ping c2 (should succeed - different path):
   
   ```bash
   c3/ # ping 172.29.20.12
   PING 172.29.20.12 (172.29.20.12): 56 data bytes
   64 bytes from 172.29.20.12: seq=0 ttl=253 time=1.166 ms
   64 bytes from 172.29.20.12: seq=1 ttl=253 time=0.876 ms
   64 bytes from 172.29.20.12: seq=2 ttl=253 time=0.831 ms
   ^C
   --- 172.29.20.12 ping statistics ---
   5 packets transmitted, 5 packets received, 0% packet loss
   ```

3. **View Deviation Entry**
   - Navigate to **Deviations** in the EDA GUI
   - You should see a deviation entry for the IRB interface

   | Name | Namespace | Labels | Annotations | Target | Operation | Path |
   |------|-----------|--------|-------------|--------|-----------|------|
   | l1-4c67... | dc1 | +1 | | l1 | Create | .interface[.name=="irb0"].subinterface[.index==1] |

   **Available Actions:**
   - **Configuration View** - See detailed comparison
   - **Accept** - Make this the new intended state
   - **Reject** - Revert to original intent

---

### Step 3: Analyze Deviation Details

1. **Click on "Configuration View"**
   - This shows the detailed comparison between intended and running values

2. **Review Deviation Information**

   **Path:**
   ```
   .interface[.name=="irb0"].subinterface[.index==1]
   ```

   **Intended Values:**
   ```json
   1  {}
   ```
   *(Empty - means admin-state should be at default, which is 'enable')*

   **Running Values:**
   ```json
   1  {
   2    "admin-state": "disable"
   3  }
   ```

   **Analysis:** The running value shows `admin-state: disable`, but the intended value expects the interface to use its default state (enabled).

---

### Step 4: Accept a Deviation

If you agree with the manual change and want it to become the new intent:

1. **Click "Accept"**
   - A confirmation dialog appears

   ```
   Accept Confirmation
   
   Are you sure you want to accept deviation on l1 at
   .interface[.name=="irb0"].subinterface[.index==1]?
   
   Select the 'Recurse' checkbox to also accept all deviations 
   below the target node and path.
   
   ☐ Recurse
   
   [Cancel]  [Accept]  [Add To Transaction]
   ```

2. **Click "Accept"**
   - The deviation is now accepted
   - The intended configuration is updated to include `admin-state: disable`

3. **Verify Acceptance**
   - The deviation detail now shows:
     - **Accepted:** `True`
     - A new button appears: **Clear Accept**

---

### Step 5: Clear Accepted Deviation

If you change your mind after accepting a deviation:

1. **Click "Clear Accept"**
   - A confirmation dialog appears

   ```
   Clear Accept Confirmation
   
   Are you sure you want to clear the accept flag for deviation on l1 at
   .interface[.name=="irb0"].subinterface[.index==1]?
   
   Select the 'Recurse' checkbox to also clear the accept flag for all 
   deviations below the target node and path.
   
   ☐ Recurse
   
   [Cancel]  [Clear Accept]  [Add To Transaction]
   ```

2. **Click "Clear Accept"**
   - The accepted flag is removed
   - The deviation becomes actionable again (can be accepted or rejected)

---

### Step 6: Reject a Deviation

To revert the device to the original intended configuration:

1. **Click "Reject"**
   - A confirmation dialog appears

   ```
   Reject Confirmation
   
   Are you sure you want to reject deviation on l1 at
   .interface[.name=="irb0"].subinterface[.index==1]?
   
   Select the 'Recurse' checkbox to also reject all deviations 
   below the target node and path.
   
   ☐ Recurse
   
   [Cancel]  [Reject]  [Add To Transaction]
   ```

2. **Click "Reject"**
   - EDA creates a transaction to restore the original configuration
   - The deviation entry disappears from the dashboard

3. **Check Transaction History**
   - Navigate to **Transactions**
   - You'll see the rejection transaction with status "complete"

---

### Step 7: Verify Remediation

1. **SSH to l1 and Verify Configuration**
   ```bash
   --{ running }--[ ]--
   A:admin@l1# info detail interface irb0
   ```

   **Expected Output:**
   ```
   interface irb0 {
       !!! EDA Source CRs: services.eda.nokia.com/v1alpha1/VirtualNetwork/compute-storage
       admin-state enable
       transceiver {
       }
       ethernet {
           flow-control {
           }
           hold-time {
               up 0
               down 0
           }
       }
       subinterface 1 {
           description irb-compute
           admin-state enable    ← Back to enabled!
           ip-mtu 1500
           ipv4 {
               admin-state enable
               allow-directed-broadcast false
               address 172.29.20.1/24 {
                   anycast-gw true
               }
               ...
           }
       }
   }
   ```

   ✅ The `admin-state` of the IRB subinterface is back to `enable`.

2. **Test Connectivity Restoration**
   - SSH to client c1
   - Ping client c3 (should now succeed):

   ```bash
   c1/ # ping 172.29.30.11
   PING 172.29.30.11 (172.29.30.11): 56 data bytes
   64 bytes from 172.29.30.11: seq=0 ttl=253 time=2.921 ms
   64 bytes from 172.29.30.11: seq=1 ttl=253 time=0.952 ms
   64 bytes from 172.29.30.11: seq=2 ttl=253 time=0.891 ms
   64 bytes from 172.29.30.11: seq=3 ttl=253 time=0.992 ms
   64 bytes from 172.29.30.11: seq=4 ttl=253 time=1.003 ms
   ^C
   --- 172.29.30.11 ping statistics ---
   5 packets transmitted, 5 packets received, 0% packet loss
   round-trip min/avg/max = 0.891/1.351/2.921 ms
   ```

   ✅ Connectivity is restored via the l3vnet virtual network!

---

## 📊 Exercise 7.3: EQL Queries

EQL (EDA Query Language) is a path-based query language for extracting information from the network state. Unlike SQL, EQL uses **dotted path notation** to navigate the data model.

> **Note:** Natural Language queries require an LLM-API key configuration and are not available in this lab environment.

---

### Understanding EQL Syntax

EQL queries use the following structure:

```
.namespace.node.srl.<path> [fields [...]] [where (...)] [order by [...]] [limit N] [sample ...]
```

#### Key Components

| Component | Description | Example |
|-----------|-------------|---------|
| **Path** | Dotted notation to data location | `.namespace.node.srl.interface` |
| **fields** | Select specific fields to return | `fields [.namespace.node.name]` |
| **where** | Filter results | `where (admin-state = "enable")` |
| **order by** | Sort results | `order by [ name ]` |
| **limit** | Limit number of results | `limit 10` |
| **sample** | Real-time sampling interval | `sample milliseconds 500` |

#### Important Differences from SQL

- **No SELECT keyword** - Use `fields` instead
- **No FROM keyword** - Start with the path directly
- **Path-based navigation** - Use dots to traverse the data model
- **Bracket notation for filters** - `[.name=="irb0"]` to filter arrays

---

### Example Queries

#### Query 1: List Major Alarms

**Query:**
```
.namespace.alarms.v1.current-alarm where (severity = "major") order by [ name ] limit 7 sample milliseconds 500
```

**Purpose:** Monitor major severity alarms in real-time (refreshing every 500ms)

**Expected Output:**

| namespace.name | name | type | severity | resource |
|----------------|------|------|----------|----------|
| dc1 | FanTrayFailure-l1-FanT... | FanTrayFailure | major | l1-FanTray1 |
| dc1 | FanTrayFailure-l1-FanT... | FanTrayFailure | major | l1-FanTray2 |
| dc1 | FanTrayFailure-l1-FanT... | FanTrayFailure | major | l1-FanTray3 |
| dc1 | CertificateUnavailable... | CertificateUnavailable | major | eda-system/eda-keycl... |

---

#### Query 2: Find Nodes with Specific IP Address

**Query:**
```
.namespace.node.srl.interface.subinterface.ipv4.address fields [.namespace.node.name] where (ip-prefix = "172.29.20.1/24")
```

**Purpose:** Identify which nodes have the IRB gateway IP configured

**Expected Output:**

| namespace.name | node.name | interface.name | subinterface.index | ip-prefix |
|----------------|-----------|----------------|-------------------|-----------|
| dc1 | l1 | irb0 | 1 | 172.29.20.1/24 |
| dc1 | l2 | irb0 | 1 | 172.29.20.1/24 |

---

#### Query 3: Find Network Instance by Learned MAC

**Query:**
```
.namespace.node.srl.network-instance.bridge-table.mac-learning.learnt-entries.mac fields [.namespace.node.srl.network-instance.name] where (address = "AA:C1:AB:97:E7:C4")
```

**Purpose:** Determine which MAC-VRF learned a specific MAC address

> **Note:** Replace the MAC address with an actual MAC from your client. Find it using:
> ```bash
> # On client
> ifconfig -a | grep HWaddr
> ```
> Generate traffic to ensure the MAC is learned before querying.

**Expected Output:**

| namespace.name | node.name | network-instance.name | address |
|----------------|-----------|----------------------|---------|
| dc1 | l4 | storage | AA:C1:AB:39:59:62 |

---

#### Query 4: Sum Interface Traffic Across Datacenter

**Query:**
```
.namespace.node.srl.interface.traffic-rate fields [ sum(in-bps) as "In", sum(out-bps) as "Out" ] where (in-bps != 0)
```

**Purpose:** Get total inbound and outbound traffic across all active interfaces

**Expected Output:**

| In | Out |
|----|-----|
| 27810 | 188306 |

---

#### Query 5: Display Process Memory Usage

**Query:**
```
.namespace.node.srl.platform.control.process order by [ memory-usage descending ]
```

**Purpose:** Monitor system resource usage by process

**Expected Output:**

| namespace.name | node.name | control.slot | pid | name | start-time | cpu-utilization | memory-usage | memory-utilization |
|----------------|-----------|--------------|-----|------|------------|-----------------|--------------|-------------------|
| dc1 | l1 | A | 2779 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 855303584 | 1 |
| dc1 | l4 | A | 2777 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 854387040 | 1 |
| dc1 | s1 | A | 2741 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 855205568 | 1 |

---

#### Query 6: Show Down Interfaces on Specific Node

**Query:**
```
.namespace.node.srl.interface fields [ admin-state, oper-state, last-change ] where (oper-state = "down" and .namespace.node.name = "l1")
```

**Purpose:** Troubleshoot connectivity issues on a specific leaf

**Expected Output:**

| namespace.name | node.name | name | admin-state | oper-state | last-change |
|----------------|-----------|------|-------------|------------|-------------|
| dc1 | l1 | ethernet-1/3 | disable | down | 2025-05-05T14:58:04.589Z |
| dc1 | l1 | ethernet-1/4 | disable | down | 2025-05-05T14:58:04.589Z |
| dc1 | l1 | ethernet-1/5 | disable | down | 2025-05-05T14:58:04.589Z |

---

#### Query 7: View IPv4 Route Table for Network Instance

**Query:**
```
.namespace.node.srl.network-instance.route-table.ipv4-unicast.route.fib-programming where (.namespace.node.name = "l4" and .namespace.node.srl.network-instance.name = "router")
```

**Purpose:** Inspect routing table entries on a specific node and network instance

**Expected Output:**

| namespace.name | node.name | network-instance.name | route.id | route.ipv4-prefix | route.origin-network-instance | route.route-owner | route.route-type | suppressed |
|----------------|-----------|----------------------|----------|-------------------|------------------------------|-------------------|------------------|------------|
| dc1 | l4 | router | 0 | 172.29.20.0/24 | router | bgp_evpn_mgr | bgp-evpn | ⊗ |
| dc1 | l4 | router | 0 | 172.29.30.11/32 | router | bgp_evpn_mgr | bgp-evpn | ⊗ |

---

#### Query 8: Display NTP Offset

**Query:**
```
.namespace.node.srl.system.ntp.server fields [COUNT(*), offset] where (.namespace.node.name = "l1")
```

**Purpose:** Monitor time synchronization health

**Expected Output:**

| COUNT(*) | offset |
|----------|--------|
| 1 | 2029 |

---

#### Query 9: Display NTP Server Address

**Query:**
```
.namespace.node.srl.system.ntp.server fields [address] where (.namespace.node.name = "l2")
```

**Purpose:** Verify NTP configuration

**Expected Output:**

| namespace.name | node.name | address |
|----------------|-----------|---------|
| dc1 | l2 | 172.18.0.1 |

---

## 💡 Practical EQL Use Cases

### Network Health Monitoring

```
# Monitor BGP session states
.namespace.node.srl.network-instance.protocols.bgp.neighbor fields [peer-address, session-state] where (session-state != "established")

# Check interface error rates
.namespace.node.srl.interface.statistics fields [name, in-errors, out-errors] where (in-errors > 0 or out-errors > 0)

# Monitor VXLAN tunnel status
.namespace.node.srl.tunnel-interface.vxlan-interface fields [vni, oper-state]
```

### Capacity Planning

```
# Check MAC table utilization
.namespace.node.srl.network-instance.bridge-table.mac-table fields [COUNT(*)] where (.namespace.node.srl.network-instance.type = "mac-vrf")

# Monitor interface bandwidth usage
.namespace.node.srl.interface.traffic-rate fields [name, in-bps, out-bps] order by [in-bps descending] limit 10
```

### Troubleshooting

```
# Find all interfaces in error-disabled state
.namespace.node.srl.interface where (oper-state = "down" and oper-down-reason = "error-disabled")

# Locate specific MAC address
.namespace.node.srl.network-instance.bridge-table.mac-learning.learnt-entries.mac where (address = "AA:C1:AB:XX:XX:XX")
```

---

## 🛠️ Troubleshooting & Tips

<details>
<summary><b>Deviation not showing up in dashboard</b></summary>

**Possible causes:**
- Deviation detection interval not elapsed
- Change made to unmanaged resource
- Monitoring service issue

**Solution:**
1. Wait for next poll cycle (typically 60 seconds)
2. Verify the resource is managed by an EDA intent
3. Check EDA monitoring service status
4. Refresh the GUI

</details>

<details>
<summary><b>EQL query returns empty results</b></summary>

**Possible causes:**
- Incorrect path syntax
- No matching data
- Wrong node/namespace filter

**Solution:**
1. Start with a simpler query without filters
2. Verify the path exists: `.namespace.node.srl.interface`
3. Check spelling and case sensitivity
4. Use the Query Builder for path auto-completion

</details>

<details>
<summary><b>Accept/Reject buttons not working</b></summary>

**Possible causes:**
- Transaction in progress
- Permissions issue
- Browser cache

**Solution:**
1. Wait for any ongoing transactions to complete
2. Check user permissions
3. Clear browser cache and reload
4. Try "Add To Transaction" instead of immediate action

</details>

<details>
<summary><b>EQL syntax error</b></summary>

**Common mistakes:**
- Using SQL keywords (SELECT, FROM)
- Missing dots in paths
- Incorrect bracket syntax for filters

**Solution:**
- Remember: EQL is path-based, not SQL
- Use `.namespace.node.srl...` not `FROM state...`
- Use `fields [...]` not `SELECT ...`
- Filter arrays with `[.key=="value"]`

</details>

---

## 🎓 Lab Summary

### What You've Accomplished

✅ **Understood Configuration Deviations**
- Created intentional deviations
- Observed impact on network connectivity
- Viewed deviation alarms and details

✅ **Mastered Deviation Workflows**
- Accepted deviations to update intent
- Cleared accepted deviations
- Rejected deviations to restore configuration
- Verified automated remediation

✅ **Learned EQL Query Language**
- Understood path-based syntax
- Wrote queries for operational monitoring
- Extracted network state information
- Built troubleshooting queries

### Key Takeaways

1. **Deviations provide visibility** into configuration drift
2. **Accept vs Reject** gives you control over intent updates
3. **EQL is path-based**, not SQL - use dotted notation
4. **Real-time monitoring** is possible with `sample` clause
5. **Operational queries** can be built for day-to-day tasks

---

## 🎯 What's Next?

Congratulations! You've completed all three parts of the SGNOG12 EDA Lab.

### Continue Your Learning

- 📖 Explore [EDA Query Language Reference](https://network.developer.nokia.com/eql)
- 🔬 Experiment with EDA REST API
- 🏗️ Design custom dashboards using EQL
- 🤝 Join the [SR Linux Community](https://learn.srlinux.dev/)

### Recommended Projects

1. **Build EQL Dashboards:** Create monitoring views for your fabric
2. **Automate Deviation Handling:** Script acceptance/rejection workflows
3. **ChatOps Integration:** Integrate EQL queries with Slack/Teams
4. **GitOps for Intents:** Manage EDA intents as code

---

## 📚 Additional Resources

### Documentation
- [EDA Query Language Reference](https://network.developer.nokia.com/eql)
- [Deviation Management Guide](https://network.developer.nokia.com/deviations)
- [SR Linux Data Model](https://yang.srlinux.dev/)

### Command Reference

**EDA GUI Navigation:**
```
Deviations → View all deviations
Deviations → [Deviation] → Configuration View
Deviations → [Deviation] → Accept / Reject / Clear Accept
Query Builder → EQL Query → Enter query → Query
```

**EQL Query Patterns:**
```
# Basic query
.namespace.node.srl.<path>

# With field selection
.namespace.node.srl.<path> fields [field1, field2]

# With filtering
.namespace.node.srl.<path> where (condition)

# With sorting
.namespace.node.srl.<path> order by [field ascending|descending]

# With limit
.namespace.node.srl.<path> limit N

# With real-time sampling
.namespace.node.srl.<path> sample milliseconds 500
```

---

## 🏁 Lab Completion

**This concludes Exercise 7.2 and 7.3 of the SGNOG12 EDA Lab!**

You have successfully:
- Detected and managed configuration deviations
- Understood accept/reject/clear workflows
- Learned EQL path-based query syntax
- Built operational queries for monitoring
- Completed the entire EDA lab series

**Total Time:** ~45 minutes

---

**Navigation:**

- [Back to Part 2: Service Overlays](part2-service-overlays.md)
- [Back to Part 1: Fabric Intent Creation](part1-fabric-intent.md)
- [Return to Main Lab Guide](README.md)

---

**Congratulations on completing the SGNOG12 EDA Lab!** You're now ready to leverage EDA for production network automation.