# 🔍 Part 3: Deviations & EQL (EDA Query Language)

> **Advanced Network Monitoring with EDA**

This guide explores EDA's powerful capabilities for **detecting configuration deviations** and **querying network state** using EQL (EDA Query Language) to gain deep insights into your infrastructure.

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [Understanding Deviations](#-understanding-deviations)
4. [Exercise 5: Configuration Deviations](#-exercise-5-configuration-deviations)
   - [Step 1: Create a Test Deviation](#step-1-create-a-test-deviation)
   - [Step 2: View Deviation in EDA GUI](#step-2-view-deviation-in-eda-gui)
   - [Step 3: Analyze Deviation Details](#step-3-analyze-deviation-details)
   - [Step 4: Accept a Deviation](#step-4-accept-a-deviation)
   - [Step 5: Clear Accepted Deviation](#step-5-clear-accepted-deviation)
   - [Step 6: Reject a Deviation](#step-6-reject-a-deviation)
   - [Step 7: Verify Remediation](#step-7-verify-remediation)
5. [Exercise 6: EQL Queries](#-exercise-6-eql-queries)
   - [Understanding EQL Syntax](#understanding-eql-syntax)
   - [Example Queries](#example-queries)
6. [Troubleshooting & Tips](#%EF%B8%8F-troubleshooting--tips)
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
- ✔️ L2 EVPN service deployed
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

## 🔧 Exercise 5: Configuration Deviations

In this exercise, we'll intentionally create a deviation to understand how EDA detects and handles configuration drift.

### Lab Scenario

- We'll disable an interface on leaf1
- This will cause connectivity issues between clients
- EDA will detect the deviation and raise alarms
- We'll explore options to accept or reject the deviation

---

### Step 1: Create a Test Deviation

1. **SSH to leaf1**
   ```bash
   ssh admin@leaf1
   ```

2. **Disable Subinterface**
   ```bash
   --{ + running }--[ ]--
   A:admin@leaf1# enter candidate
   
   --{ + candidate shared default }--[ ]--
   A:admin@leaf1# interface ethernet-1/50 subinterface 0
   
   --{ + candidate shared default }--[ interface ethernet-1/50 subinterface 0 ]--
   A:admin@leaf1# admin-state disable
   
   --{ +* candidate shared default }--[ ethernet-1/50 subinterface 0 ]--
   A:admin@leaf1# commit now
   All changes have been committed. Leaving candidate mode.
   ```

   > **What happened?** We manually disabled an interface that EDA created. This is a deviation because EDA expects this interface to be enabled.

---

### Step 2: View Deviation in EDA GUI

1. **Check for Alarms**
   - Navigate to **Alarms** in the EDA GUI
   - You should see alarms generated immediately after the commit:
     - `DefaultRouterDegraded` (Critical severity)
     - `DefaultInterfaceDown` (Critical severity)

   | Severity | Type | Occurrences | Resource | Last Changed |
   |----------|------|-------------|------|--------------|
   | Critical | DefaultRouterDegraded | 1 | router-leaf1 | Wed Jun 18 2025, 14:29:35 EDT |
   | Critical | DefaultInterfaceDown | 1 | interface-leaf1-ethernet-1-50 | Wed Jun 18 2025, 14:29:35 EDT |

2. **View Deviation Entry**
   - Navigate to **Deviations** in the EDA GUI
   - You should see a deviation entry for the interface

   | Name | Namespace | Labels | Annotations | Target | Operation | Path |
   |------|-----------|--------|-------------|--------|-----------|------|
   | leaf1-550d3... | clab-dc-{GROUP_ID}-eda | +1 | | leaf1 | Create | .interface{.name=="ethernet-1/50"}.subinterface{.index==0} |

   **Available Actions:**
   - **View** - See detailed comparison
   - **Accept** - Make this the new intended state
   - **Reject** - Revert to original intent

---

### Step 3: Analyze Deviation Details

1. **Click on "View"**
   - This shows the detailed comparison between intended and running values

2. **Review Deviation Information**

   **Path:**
   ```
   .interface{.name=="ethernet-1/50"}.subinterface{.index==0}
   ```

   **Intended Values:**
   ```json
   1  "admin-state": "enable"
   ```

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
   
   Are you sure you want to accept deviation on leaf1 at
   .interface{.name=="ethernet-1/50"}.subinterface{.index==0}?
   
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
   .interface{.name=="ethernet-1/50"}.subinterface{.index==0}?
   
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
   .interface{.name=="ethernet-1/50"}.subinterface{.index==0}?
   
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

1. **SSH to leaf1 and Verify Configuration**
   ```bash
   --{ running }--[ ]--
   A:admin@leaf1# info detail interface ethernet-1/1
   ```

   **Expected Output:**
   ```
       !!! EDA Source CRs: interfaces.eda.nokia.com/v1alpha1/Interface/leaf1-ethernet-1-1
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
       subinterface 4097 {
        !!! EDA Source CRs: services.eda.nokia.com/v1/BridgeInterface/client1
        type bridged
        description client1
        admin-state enable
        ipv4 {
            admin-state disable
            allow-directed-broadcast false
            unnumbered {
                admin-state disable
            }
            arp {
                duplicate-address-detection true
                timeout 14400
                learn-unsolicited false
                proxy-arp false
                host-route {
                }
            }
          }
               ...
   ```

   ✅ The `admin-state` of the subinterface is back to `enable`.


---

## 📊 Exercise 6: EQL Queries

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
- **Bracket notation for filters** - `[.name=="ethernet-1/1"]` to filter arrays

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
| clab-dc-{GROUP_ID}-eda | FanTrayFailure-leaf1-FanT... | FanTrayFailure | major | leaf1-FanTray1 |
| clab-dc-{GROUP_ID}-eda | FanTrayFailure-leaf1-FanT... | FanTrayFailure | major | leaf1-FanTray2 |
| clab-dc-{GROUP_ID}-eda | FanTrayFailure-leaf1-FanT... | FanTrayFailure | major | leaf1-FanTray3 |
| clab-dc-{GROUP_ID}-eda | CertificateUnavailable... | CertificateUnavailable | major | eda-system/eda-keycl... |

---

#### Query 2: Find Nodes with Specific IP Address

**Query:**
```
.namespace.node.srl.interface.subinterface.ipv4.address fields [.namespace.node.name] where (ip-prefix = "11.0.0.1/32")
```

**Purpose:** Identify which nodes have the system IP configured

**Expected Output:**

| namespace.name | node.name | interface.name | subinterface.index | ip-prefix |
|----------------|-----------|----------------|-------------------|-----------|
| clab-dc-{GROUP_ID}-eda | leaf3 | system0 | 1 | 11.0.0.1/32 |

---

#### Query 3: Find Network Instance by Learned MAC

**Query:**
```
.namespace.node.srl.network-instance.bridge-table.mac-learning.learnt-entries.mac fields [.namespace.node.srl.network-instance.name] where (address = "AA:C1:AB:64:CD:5B")
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
| clab-dc-{GROUP_ID}-eda | leaf1 | l2vnet | AA:C1:AB:64:CD:5B |

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
| clab-dc-{GROUP_ID}-eda | leaf1 | A | 2779 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 855303584 | 1 |
| clab-dc-{GROUP_ID}-eda | leaf2 | A | 2777 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 854387040 | 1 |
| clab-dc-{GROUP_ID}-eda | spine1 | A | 2741 | sr_xdp_lc | 2025-05-05T14:53:31.000Z | 0 | 855205568 | 1 |

---

#### Query 6: Show Down Interfaces on Specific Node

**Query:**
```
.namespace.node.srl.interface fields [ admin-state, oper-state, last-change ] where (oper-state = "down" and .namespace.node.name = "leaf1")
```

**Purpose:** Troubleshoot connectivity issues on a specific leaf

**Expected Output:**

| admin-state | oper-state | last-change |
|-------------|------------|-------------|
| disable | down | 2025-05-05T14:58:04.589Z |
| disable | down | 2025-05-05T14:58:04.589Z |
| disable | down | 2025-05-05T14:58:04.589Z |

---

#### Query 7: View IPv4 Route Table for Network Instance

**Query:**
```
.namespace.node.srl.network-instance.route-table.ipv4-unicast.route.fib-programming where (.namespace.node.name = "leaf1" and .namespace.node.srl.network-instance.name = "default")
```

**Purpose:** Inspect routing table entries on a specific node and network instance

**Expected Output:**

| namespace.name | node.name | network-instance.name | route.id | route.ipv4-prefix | route.origin-network-instance | route.route-owner | route.route-type | suppressed |
|----------------|-----------|----------------------|----------|-------------------|------------------------------|-------------------|------------------|------------|
| clab-dc-{GROUP_ID}-eda | leaf1 | default | 0 | 11.0.0.1/32 | router | bgp_mgr | bgp | ⊗ |
| clab-dc-{GROUP_ID}-eda | leaf1 | default | 0 | 11.0.0.2/32 | router | bgp_mgr | bgp | ⊗ |


---

## 💡 Practical EQL Use Cases

### Network Health Monitoring

```
# Monitor BGP session states
.namespace.node.srl.network-instance.protocols.bgp.neighbor fields [peer-address, session-state] where (session-state = "established")

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

---

## 📚 Additional Resources

### Documentation
- [Nokia EDA Documentation](https://docs.eda.dev/)
- [SR Linux Data Model](https://yang.srlinux.dev/)

---

## 🏁 Lab Completion

**This concludes Exercises 5 and 6 of the SGNOG12 EDA Lab!**

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
