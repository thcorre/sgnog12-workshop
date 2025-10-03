# 🔍 Part 3: Deviations & EQL (EDA Query Language)

> **Advanced Network Monitoring and Configuration Management with EDA**

This guide explores EDA's powerful capabilities for **detecting configuration deviations** and **querying network state** using EQL (EDA Query Language) to gain deep insights into your infrastructure.

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [Understanding Deviations](#-understanding-deviations)
4. [Step-by-Step Guide](#-step-by-step-guide)
   - [Step 1: View Configuration Deviations](#step-1-view-configuration-deviations)
   - [Step 2: Analyze Deviation Sources](#step-2-analyze-deviation-sources)
   - [Step 3: Remediate Deviations](#step-3-remediate-deviations)
   - [Step 4: Introduction to EQL](#step-4-introduction-to-eql)
   - [Step 5: Writing EQL Queries](#step-5-writing-eql-queries)
   - [Step 6: Building Custom Reports](#step-6-building-custom-reports)
   - [Step 7: Automating Compliance Checks](#step-7-automating-compliance-checks)
5. [Advanced EQL Examples](#-advanced-eql-examples)
6. [Troubleshooting & Tips](#-troubleshooting--tips)
7. [Lab Summary](#-lab-summary)

---

## 🎯 Overview

In this lab, you will:

- ✅ Understand what configuration deviations are and why they matter
- ✅ Detect and analyze deviations in your EDA-managed fabric
- ✅ Learn remediation strategies for configuration drift
- ✅ Master EQL syntax and query structure
- ✅ Query network state for operational insights
- ✅ Build custom dashboards and reports
- ✅ Automate compliance validation

**Estimated time:** 30 minutes

---

## ✅ Prerequisites

Before starting Part 3, ensure you have:

- ✔️ **Completed** [Part 1: Fabric Intent Creation](part1-fabric-intent.md)
- ✔️ **Completed** [Part 2: Service Overlays](part2-service-overlays.md) (recommended)
- ✔️ Active fabric with committed intents
- ✔️ Access to EDA GUI and API
- ✔️ Basic understanding of:
  - JSON/YAML data structures
  - SQL-like query syntax (helpful but not required)

---

## 📚 Understanding Deviations

### What is a Configuration Deviation?

A **deviation** occurs when the actual configuration on a device differs from the **intended state** defined in EDA.

#### Common Deviation Causes

| Cause | Example |
|-------|---------|
| **Manual Changes** | Operator modifies config via CLI outside EDA |
| **External Automation** | Ansible/Python scripts change configuration |
| **Device Reload** | Config not saved, reverts on reboot |
| **Software Bug** | Device fails to apply certain configurations |
| **Network Events** | Dynamic protocols override static config |

### Why Deviations Matter

- ❌ **Configuration Drift:** Network state diverges from intended design
- ❌ **Compliance Violations:** Security policies not enforced
- ❌ **Operational Risk:** Unexpected behavior, outages
- ❌ **Audit Issues:** Cannot prove configuration compliance

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
                     │ Actual       │ ───> │ Alert/      │
                     │ Device State │      │ Report      │
                     └──────────────┘      └─────────────┘
```

---

## 📖 Step-by-Step Guide

### Step 1: View Configuration Deviations

Navigate to **Monitoring → Deviations** in the EDA GUI.

#### Deviation Dashboard

The dashboard shows:

| Column | Description |
|--------|-------------|
| **Node** | Device with deviation |
| **Severity** | Critical / Warning / Info |
| **Deviation Type** | Missing config / Extra config / Value mismatch |
| **Path** | JSON path to the deviated configuration |
| **Expected Value** | What EDA intended |
| **Actual Value** | What's currently on device |
| **Detected** | Timestamp of deviation detection |

#### Create a Test Deviation

To understand deviation detection, let's intentionally create one:

```bash
# SSH to leaf1
ssh admin@leaf1

# Make a manual change to an interface managed by EDA
enter candidate

set /interface ethernet-1/1 description "MANUAL_CHANGE"

commit now
```

Wait 30-60 seconds for EDA to detect the deviation.

---

### Step 2: Analyze Deviation Sources

Click on a deviation to view details:

#### Deviation Detail View

```json
{
  "node": "leaf1",
  "path": "/interface[name=ethernet-1/1]/description",
  "expected": "to-spine1",
  "actual": "MANUAL_CHANGE",
  "severity": "warning",
  "intent": "myfabric",
  "detectedAt": "2024-10-03T14:23:45Z"
}
```

#### Severity Levels

- 🔴 **Critical:** Security policy violation, service-impacting
- 🟡 **Warning:** Non-critical deviation from intent
- 🔵 **Info:** Cosmetic differences, no operational impact

---

### Step 3: Remediate Deviations

EDA offers multiple remediation strategies:

#### Option 1: Automatic Reconciliation

Enable auto-remediation for specific intents:

1. Navigate to **Fabrics → myfabric → Settings**
2. Enable **Auto-Reconciliation**
3. Set **Reconciliation Interval** (e.g., 5 minutes)

EDA will automatically re-apply the intent to fix deviations.

#### Option 2: Manual Re-Commit

1. Go to **Transactions → History**
2. Find the original commit
3. Click **Re-Apply**
4. Run **Dry-Run** to preview changes
5. **Commit** to fix deviations

#### Option 3: Update Intent to Match Reality

If the manual change was intentional:

1. Update the intent to reflect the new desired state
2. Commit the updated intent
3. Deviation will be resolved

#### Verification

```bash
# On leaf1, verify config is back to intended state
show interface ethernet-1/1 description

# Should show: "to-spine1"
```

---

### Step 4: Introduction to EQL

**EQL (EDA Query Language)** is a powerful SQL-like language for querying network state.

#### EQL Components

| Component | Description | Example |
|-----------|-------------|---------|
| **SELECT** | Fields to retrieve | `SELECT node, interface` |
| **FROM** | Data source (config/state) | `FROM state.interfaces` |
| **WHERE** | Filter conditions | `WHERE admin_state = "enable"` |
| **ORDER BY** | Sort results | `ORDER BY node ASC` |
| **LIMIT** | Limit result count | `LIMIT 10` |

#### Accessing EQL

Navigate to **Analytics → Query Explorer** in the EDA GUI.

---

### Step 5: Writing EQL Queries

#### Example 1: List All Interfaces

```sql
SELECT
  node,
  interface.name,
  interface.admin_state,
  interface.oper_state
FROM state.interfaces
ORDER BY node, interface.name
```

**Result:**
```
node    | interface.name    | admin_state | oper_state
--------|-------------------|-------------|------------
leaf1   | ethernet-1/1      | enable      | up
leaf1   | ethernet-1/2      | enable      | up
spine1  | ethernet-1/1      | enable      | up
```

---

#### Example 2: Find Down Interfaces

```sql
SELECT
  node,
  interface.name,
  interface.oper_state,
  interface.last_change
FROM state.interfaces
WHERE
  interface.admin_state = "enable"
  AND interface.oper_state = "down"
```

---

#### Example 3: BGP Neighbor Status

```sql
SELECT
  node,
  bgp.neighbor.address,
  bgp.neighbor.peer_as,
  bgp.neighbor.session_state
FROM state.protocols.bgp.neighbors
WHERE bgp.neighbor.session_state != "established"
```

---

#### Example 4: MAC Address Table Query

```sql
SELECT
  node,
  network_instance.name,
  mac.address,
  mac.type,
  mac.last_update
FROM state.network_instances.bridge_table.mac_table
WHERE network_instance.name = "customer-a-l2"
ORDER BY mac.last_update DESC
LIMIT 50
```

---

#### Example 5: EVPN Route Count per Node

```sql
SELECT
  node,
  COUNT(evpn_route.route_type) as route_count
FROM state.bgp.evpn.routes
GROUP BY node
ORDER BY route_count DESC
```

---

### Step 6: Building Custom Reports

#### Create a Fabric Health Report

```sql
-- Comprehensive fabric health query
SELECT
  fabric.name,
  COUNT(DISTINCT node.name) as total_nodes,
  COUNT(DISTINCT bgp.neighbor) as bgp_sessions,
  SUM(CASE WHEN bgp.session_state = "established" THEN 1 ELSE 0 END) as bgp_up,
  COUNT(DISTINCT interface.name) as total_interfaces,
  SUM(CASE WHEN interface.oper_state = "up" THEN 1 ELSE 0 END) as interfaces_up
FROM state.fabric
GROUP BY fabric.name
```

#### Save and Schedule Reports

1. Click **Save Query** in Query Explorer
2. Name: "Daily Fabric Health Report"
3. Click **Schedule**
4. Set frequency: Daily at 08:00
5. Set notification: Email to ops@company.com

---

### Step 7: Automating Compliance Checks

#### Define Compliance Rules

Create queries that validate policy compliance:

#### Rule 1: All Underlay Links Must Use /31

```sql
SELECT
  node,
  interface.name,
  interface.ipv4_address,
  interface.prefix_length
FROM config.interfaces
WHERE
  interface.labels CONTAINS "eda.nokia.com/role=interSwitch"
  AND interface.prefix_length != 31
```

If this returns results, you have a compliance violation.

---

#### Rule 2: BGP Sessions Must Use MD5 Authentication

```sql
SELECT
  node,
  bgp.neighbor.address,
  bgp.neighbor.auth_enabled
FROM config.protocols.bgp.neighbors
WHERE bgp.neighbor.auth_enabled = false
```

---

#### Rule 3: VXLAN VNIs Must Be in Allocated Range

```sql
SELECT
  node,
  network_instance.name,
  vxlan.vni
FROM config.network_instances
WHERE
  vxlan.vni < 10000
  OR vxlan.vni > 99999
```

---

## 🎨 Advanced EQL Examples

### Time-Series Analysis

```sql
-- Interface utilization trend over last 24 hours
SELECT
  node,
  interface.name,
  TIME_BUCKET(timestamp, '1 hour') as hour,
  AVG(interface.traffic.out_bps) as avg_out_bps,
  MAX(interface.traffic.out_bps) as max_out_bps
FROM metrics.interface_statistics
WHERE
  timestamp > NOW() - INTERVAL '24 hours'
  AND interface.name LIKE 'ethernet-1/%'
GROUP BY node, interface.name, hour
ORDER BY hour DESC
```

---

### Anomaly Detection

```sql
-- Find interfaces with unusually high error rates
SELECT
  node,
  interface.name,
  interface.errors.in_errors,
  interface.errors.out_errors,
  (interface.errors.in_errors + interface.errors.out_errors) as total_errors
FROM state.interfaces
WHERE
  (interface.errors.in_errors + interface.errors.out_errors) > 100
ORDER BY total_errors DESC
```

---

### Capacity Planning

```sql
-- Identify VXLAN VNI pool utilization
SELECT
  pool.name,
  pool.total_capacity,
  pool.allocated,
  ROUND((pool.allocated * 100.0 / pool.total_capacity), 2) as utilization_percent
FROM state.allocation_pools
WHERE pool.type = "vni"
ORDER BY utilization_percent DESC
```

---

### Cross-Intent Analysis

```sql
-- Find all services using a specific VLAN
SELECT
  intent.name,
  intent.type,
  vlan.id,
  COUNT(DISTINCT node) as node_count
FROM config.intents
WHERE vlan.id = 100
GROUP BY intent.name, intent.type, vlan.id
```

---

## 🛠️ Troubleshooting & Tips

<details>
<summary><b>❓ Deviation not showing up in dashboard</b></summary>

**Possible causes:**
- Deviation detection interval not elapsed
- Change made to unmanaged resource
- Monitoring service issue

**Solution:**
1. Wait for next poll cycle (default: 60 seconds)
2. Verify the resource is managed by an intent
3. Check EDA monitoring service status

</details>

<details>
<summary><b>❓ EQL query returns empty results</b></summary>

**Possible causes:**
- Incorrect data source (config vs state)
- Syntax error in WHERE clause
- Data not yet collected

**Solution:**
1. Verify data source: `FROM state.X` vs `FROM config.X`
2. Test without WHERE clause first
3. Check query syntax highlighting for errors
4. Verify telemetry is being collected

</details>

<details>
<summary><b>❓ Auto-reconciliation not fixing deviations</b></summary>

**Possible causes:**
- Conflicting manual changes applied repeatedly
- Intent doesn't cover the deviated resource
- Device rejecting configuration

**Solution:**
1. Check transaction logs for commit failures
2. Verify intent scope covers the resource
3. Review device logs for config errors
4. Consider updating intent instead of forcing reconciliation

</details>

<details>
<summary><b>❓ EQL query performance is slow</b></summary>

**Possible causes:**
- Querying large dataset without filters
- Missing indexes on queried fields
- Complex JOIN operations

**Solution:**
1. Add WHERE clause to filter data
2. Use LIMIT to restrict result size
3. Query state (cached) instead of real-time device data
4. Break complex queries into smaller parts

</details>

---

## 🎓 Lab Summary

Congratulations! You've completed all three parts of the SGNOG12 EDA Lab. 🎉

### What You've Learned

#### Part 1: Fabric Intent Creation
- ✅ Created automated leaf-spine fabric with EDA intents
- ✅ Used dry-run for safe configuration preview
- ✅ Verified fabric health and BGP sessions

#### Part 2: Service Overlays
- ✅ Deployed EVPN-VXLAN Layer 2 and Layer 3 services
- ✅ Configured MAC-VRF and IP-VRF instances
- ✅ Implemented IRB for inter-subnet routing

#### Part 3: Deviations & EQL
- ✅ Detected and remediated configuration deviations
- ✅ Wrote powerful EQL queries to extract network insights
- ✅ Built custom compliance checks and reports

---

## 🚀 Next Steps

### Continue Your Learning

- 📖 Explore [Nokia EDA Advanced Patterns](https://network.developer.nokia.com/)
- 🔬 Experiment with EDA REST API for programmatic control
- 🏗️ Design intent-based automation for your own use cases
- 🤝 Join the [SR Linux Community](https://learn.srlinux.dev/)

### Recommended Projects

1. **Multi-DC Fabric:** Extend your fabric across multiple data centers
2. **Service Chaining:** Implement advanced service insertion
3. **ChatOps Integration:** Integrate EQL queries with Slack/Teams
4. **GitOps Workflow:** Manage EDA intents as code in Git

---

## 📚 Additional Resources

### Documentation
- [EDA Query Language Reference](https://network.developer.nokia.com/eql)
- [Deviation Management Guide](https://network.developer.nokia.com/deviations)
- [EDA REST API Documentation](https://network.developer.nokia.com/api)

### Learning Resources
- [Nokia Network Developer Portal](https://network.developer.nokia.com/)
- [SR Linux Learn Portal](https://learn.srlinux.dev/)
- [EVPN-VXLAN Design Guide](https://documentation.nokia.com/)

---

## 📝 Feedback

Thank you for completing the SGNOG12 EDA Lab!

We'd love to hear your feedback:
- What worked well?
- What could be improved?
- What topics would you like to see in future labs?

---

**Navigation:**

- 🔙 [Back to Part 2: Service Overlays](part2-service-overlays.md)
- 🔙 [Back to Part 1: Fabric Intent](part1-fabric-intent.md)
- 🏠 [Return to Main Lab Guide](README.md)

---

**Well done on completing the lab!** 🌟 You're now ready to leverage EDA for production network automation!
