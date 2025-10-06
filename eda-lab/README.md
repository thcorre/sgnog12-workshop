# 🌐 SGNOG12 EDA Lab

> **Hands-on Nokia EDA Workshop**

Welcome to the SGNOG12 EDA Lab! 
This workshop provides **three comprehensive guides** to help you master Nokia's Event-Driven Automation (EDA) platform through practical, hands-on exercises.

---

## 📚 Workshop Structure

This lab is divided into three progressive parts:

### 🏗️ [Part 1: Fabric Intent Creation & Verification](part1-fabric-intent.md)

Learn how to create and verify an IP leaf-spine underlay fabric using EDA intents.

**What you'll learn:**
- Creating fabric intents with proper selectors and allocation pools
- Using dry-run to preview configuration changes
- Verifying fabric health and status
- Validating configurations on SR Linux devices

**Duration:** ~45 minutes

---

### 🔄 [Part 2: Service Overlays](part2-service-overlays.md)

Build on your fabric foundation by implementing service overlays.

**What you'll learn:**
- Configuring EVPN-VXLAN overlays
- Creating Layer 2 and Layer 3 services
- Multi-tenancy and network slicing
- Service verification and troubleshooting

**Duration:** ~60 minutes

---

### 🔍 [Part 3: Deviations & EQL (EDA Query Language)](part3-deviations-eql.md)

Master advanced EDA capabilities for monitoring and querying your network state.

**What you'll learn:**
- Understanding and managing configuration deviations
- Writing EQL queries to extract network insights
- Building custom dashboards and reports
- Automating compliance checks

**Duration:** ~45 minutes

---

## ✅ Prerequisites

Before starting this lab, ensure you have:

- ✔️ An operational **Nokia EDA environment** with GUI access
- ✔️ A discovered/imported topology (leaf-spine architecture)
- ✔️ Pre-created **allocation pools**:
  - System IPs (IPv4)
  - Inter-switch link IPs (/31 pools)
  - ASN pool for BGP
- ✔️ **Labels** configured on:
  - Leaf nodes (`eda.nokia.com/role=leaf`)
  - Spine nodes (`eda.nokia.com/role=spine`)
  - Inter-switch links (`eda.nokia.com/role=interSwitch`)
- ✔️ SSH access to SR Linux devices for verification
- ✔️ Basic understanding of:
  - IP networking and BGP
  - EVPN-VXLAN concepts (for Part 2)
  - Network automation principles

---

## 🚀 Getting Started

**Recommended path:** Complete the parts in sequence, as each builds on concepts from the previous section.

1. **Start here:** [Part 1: Fabric Intent Creation & Verification](part1-fabric-intent.md)
2. **Continue with:** [Part 2: Service Overlays](part2-service-overlays.md)
3. **Finish with:** [Part 3: Deviations & EQL](part3-deviations-eql.md)

> **💡 Tip:** Each guide includes troubleshooting sections and verification steps. Don't skip the verification—it's crucial for understanding!

---

## 📖 Lab Topology

```
                    ┌─────────┐  ┌─────────┐
                    │ spine1  │  │ spine2  │
                    │ (65000) │  │ (65000) │
                    └────┬────┘  └────┬────┘
                         │            │
          ┌──────────────┼────────────┼──────────────┐
          │              │            │              │
     ┌────┴────┐    ┌────┴────┐  ┌───┴─────┐   ┌────┴────┐
     │  leaf1  │    │  leaf2  │  │  leaf3  │   │  leaf4  │
     │ (65001) │    │ (65002) │  │ (65003) │   │ (65004) │
     └─────────┘    └─────────┘  └─────────┘   └─────────┘
```

- **Underlay:** eBGP with unique ASNs per leaf
- **Overlay:** eBGP EVPN
- **Links:** /31 point-to-point addressing

---

## 🛠️ Additional Resources

### Documentation
- [Nokia EDA Documentation](https://network.developer.nokia.com/)
- [SR Linux Documentation](https://documentation.nokia.com/srlinux/)
- [EVPN-VXLAN Guide](https://learn.srlinux.dev/)

### Tools
- [EDA REST API Reference](https://network.developer.nokia.com/api)
- [SR Linux CLI Reference](https://documentation.nokia.com/srlinux/latest/cli-reference/)

---

## 🤝 Getting Help

If you encounter issues during the lab:

1. Check the **Troubleshooting** section in each guide
2. Verify your prerequisites are met
3. Review the EDA transaction logs
4. Ask your lab instructor for assistance

---

## 📝 Feedback

Have suggestions for improving this lab? Found an issue?

Please share your feedback with the lab organizers!

---

**Ready to begin?** 🎯 Head to [Part 1: Fabric Intent Creation & Verification](part1-fabric-intent.md)

**Happy networking!** 🚀
