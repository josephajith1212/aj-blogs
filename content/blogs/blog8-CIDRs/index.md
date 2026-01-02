+++
date = '2025-12-19T17:03:00-05:00'
draft = false
title = 'CIDR Basics and Practical Use Cases in AWS'
+++

Hello world! If you've been working with AWS, you've probably bumped into CIDR notation at some point. Whether you're setting up VPCs, security groups, or route tables, CIDR blocks are everywhere. I'll be honest, when I first started my DevOps journey, CIDR notation felt like absolute magic. But once it clicked for me, it became one of my go-to tools for designing robust cloud infrastructure.

Let me walk you through what CIDR actually is, how to calculate it, and show you some real world situations where I've used it in my AWS environments.

---

## What Even Is CIDR?

CIDR stands for Classless Inter-Domain Routing. I know, fancy name. But here's the thing: it's just a shorthand way to describe a range of IP addresses. Instead of saying "all IP addresses from 10.0.0.0 to 10.0.0.255," you can just write `10.0.0.0/24` and boom, you've described the same thing in a much cleaner way.

### The Basics: How CIDR Works

An IPv4 address is made up of 32 bits total. These 32 bits are split into two parts: the network part and the host part. The CIDR notation (the `/xx` number) tells you exactly where that split happens.

For example, in `10.0.0.0/24`, the `/24` means:

- First 24 bits = the network part (this stays the same for all addresses in the range)
- Last 8 bits = the host part (this can vary)

The network part identifies which subnet you're in. The host part identifies individual devices within that subnet.

Let me break down `10.0.0.0/24` in binary to make it clearer:

```
10.0.0.0 in binary = 00001010.00000000.00000000.00000000
/24 means first 24 bits are fixed

Network part (first 24 bits):  00001010.00000000.00000000 (this is always the same)
Host part (last 8 bits):       .00000000 to .11111111 (these can vary)

So the range is: 10.0.0.0 to 10.0.0.255
```

Simple, right? The `/24` just tells you where the dividing line is between the network and host portions.

### How to Calculate CIDR Ranges

Here's the formula I use constantly. It's super simple:

**Host bits = 32 minus CIDR number**

**Number of addresses = 2^(host bits)**

Let me walk through a few examples so you see how it works.

For `/24`:

- Host bits = 32 - 24 = 8 bits
- Number of addresses = 2^8 = 256 addresses
- Usable IPs = 256 minus 2 (network and broadcast) = 254 usable IPs

For `/16`:

- Host bits = 32 - 16 = 16 bits
- Number of addresses = 2^16 = 65,536 addresses
- Usable IPs = 65,536 minus 2 = 65,534 usable IPs

For `/30`:

- Host bits = 32 - 30 = 2 bits
- Number of addresses = 2^2 = 4 addresses
- Usable IPs = 4 minus 2 = 2 usable IPs

For `/32`:

- Host bits = 32 - 32 = 0 bits
- Number of addresses = 2^0 = 1 address (a single host)
- Usable IPs = 1 (it's just one IP, no network or broadcast address)

### Common CIDR Notations at a Glance

Here's a quick reference of the ones you'll see most often:

- `/32` = 1 IP address (single host, super specific)
- `/30` = 4 IP addresses (2 usable, great for point to point links)
- `/24` = 256 IP addresses (254 usable, perfect for small to medium subnets)
- `/16` = 65,536 IP addresses (65,534 usable, great for large networks)
- `/8` = 16,777,216 IP addresses (huge networks, rarely used in AWS)

### Why Does CIDR Matter?

Once you understand CIDR, you can design networks that are exactly the right size. Too small, and you run out of IPs. Too big, and you're wasting address space. CIDR lets you be precise about it.

In AWS, everything uses CIDR. Your VPC needs a CIDR block. Each subnet needs a CIDR block. Security groups use CIDR to define what traffic is allowed. Route tables use CIDR to decide where packets should go. So getting comfortable with this notation early on saves you tons of confusion later.

---

## How I Use CIDR in AWS

Let me give you a real world example from one of my home lab projects. I was setting up a VPC in AWS to run a few microservices in Kubernetes, and I needed to plan my network carefully.

### Creating a VPC and Subnets

When I created my VPC, I decided to use `10.0.0.0/16` as my overall network block. This gave me plenty of room to work with. Then I carved that up into smaller subnets:

```yaml
VPC:
  CIDR: 10.0.0.0/16
  Total IPs: 65,536 (254 usable per subnet once divided)

Subnets:
  PublicSubnet1:
    CIDR: 10.0.1.0/24
    IPs: 256 (254 usable)
    AZ: us-east-1a

  PublicSubnet2:
    CIDR: 10.0.2.0/24
    IPs: 256 (254 usable)
    AZ: us-east-1b

  PrivateSubnet1:
    CIDR: 10.0.10.0/24
    IPs: 256 (254 usable)
    AZ: us-east-1a

  PrivateSubnet2:
    CIDR: 10.0.11.0/24
    IPs: 256 (254 usable)
    AZ: us-east-1b
```

Notice how I spaced things out? I used `/24` for each subnet, which gives me 256 IPs per subnet. For my use case, that's more than enough. I could spin up an EKS cluster, a few RDS instances, and still have room to grow.

The beauty of this approach is that I'm not wasting the address space. By choosing appropriate CIDR blocks, I can scale my infrastructure without having to redesign my entire VPC later.

### Setting Up Security Groups

This is where CIDR really shines for me. Security groups in AWS use CIDR notation to control who can talk to what. Let me walk you through a scenario.

I had an EKS cluster that needed to talk to an RDS database. Instead of just opening port 5432 to the entire internet (please don't do that!), I used the CIDR block of my private subnets where the EKS nodes lived.

```yaml
RDSSecurityGroup:
  InboundRules:
    - Protocol: TCP
      Port: 5432
      Source: 10.0.10.0/24
      Description: "Allow from EKS nodes in AZ-1a"

    - Protocol: TCP
      Port: 5432
      Source: 10.0.11.0/24
      Description: "Allow from EKS nodes in AZ-1b"
```

This way, only my Kubernetes nodes can reach the database. It's secure, precise, and scales with my infrastructure.

### Managing Kubernetes Pod Networks with CIDR

When I deployed EKS on AWS, I needed to think carefully about CIDR blocks for the pods themselves. My VPC uses `10.0.0.0/16`, but the Kubernetes pods need their own IP space. I configured my cluster with a pod CIDR of `100.64.0.0/16`, which is completely separate from my VPC network.

```yaml
EKSCluster:
  VPC_CIDR: 10.0.0.0/16
  Pod_CIDR: 100.64.0.0/16

  Nodes:
    - Node1_VPC_IP: 10.0.1.50 (from subnet 10.0.1.0/24)
    - Node2_VPC_IP: 10.0.2.75 (from subnet 10.0.2.0/24)

  Pods:
    - Pod1_IP: 100.64.0.10 (from pod CIDR)
    - Pod2_IP: 100.64.0.11 (from pod CIDR)
    - Pod3_IP: 100.64.1.5 (from pod CIDR)
```

This separation is clever. My worker nodes live in the VPC subnet (10.0.x.x), but the pods they run get IPs from a completely different range (100.64.x.x). This prevents IP conflicts and gives me tons of flexibility. I can have hundreds of pods running on just a few nodes without worrying about running out of IPs in my subnets.

### Managing Database Replication with CIDR Rules

Here's a practical example I ran into recently. I have an RDS instance for production in one AWS region and a read replica in another region. I needed to allow replication traffic between them using specific CIDR blocks.

My production database is in us-east-1 with a security group that has a CIDR block of `10.0.0.0/16`. My replica is in us-west-2 with a different VPC using `10.1.0.0/16`. I set up an inter-region VPC peering connection and configured the security groups like this:

```yaml
ProductionRDSSecurityGroup:
  InboundRules:
    - Protocol: TCP
      Port: 3306
      Source: 10.1.0.0/16
      Description: "Allow MySQL replication from us-west-2 replica VPC"

ReplicaRDSSecurityGroup:
  InboundRules:
    - Protocol: TCP
      Port: 3306
      Source: 10.0.0.0/16
      Description: "Allow read queries from production VPC"
```

By using the VPC CIDR blocks instead of individual IP addresses, the security groups automatically work for any database instance I launch in those VPCs. If I add new instances later, the rules still apply. It's much more scalable than hardcoding individual IPs.

---

## CIDR Quick Reference Guide

Here's a handy cheatsheet I keep bookmarked for quick lookups. You'll end up memorizing these pretty quickly, but when you need a fast reference, this is it.

### CIDR Notations and Host Count

| CIDR Notation | Total Addresses | Usable IPs | Common Use Case                                 |
| ------------- | --------------- | ---------- | ----------------------------------------------- |
| `/32`         | 1               | 1          | Single host, specific IP                        |
| `/31`         | 2               | 2          | Point to point links (RFC 3021)                 |
| `/30`         | 4               | 2          | VPN tunnels, router links                       |
| `/29`         | 8               | 6          | Small lab environment                           |
| `/28`         | 16              | 14         | Tiny subnet                                     |
| `/27`         | 32              | 30         | Small subnet                                    |
| `/26`         | 64              | 62         | Medium subnet                                   |
| `/25`         | 128             | 126        | Medium subnet                                   |
| `/24`         | 256             | 254        | Standard subnet (AWS default for many services) |
| `/23`         | 512             | 510        | Larger subnet                                   |
| `/22`         | 1,024           | 1,022      | Large subnet                                    |
| `/21`         | 2,048           | 2,046      | Very large subnet                               |
| `/20`         | 4,096           | 4,094      | Very large subnet                               |
| `/16`         | 65,536          | 65,534     | Typical VPC size                                |
| `/15`         | 131,072         | 131,070    | Large VPC                                       |
| `/8`          | 16,777,216      | 16,777,214 | Entire RFC 1918 block                           |

### Quick Calculation Cheat

If you need to calculate on the fly, remember this formula:

**Number of Addresses = 2^(32 - CIDR)**

**Usable IPs = 2^(32 - CIDR) - 2** (subtract 2 for network and broadcast addresses)

Examples:

- `/24`: 2^(32-24) = 2^8 = 256 addresses (254 usable)
- `/16`: 2^(32-16) = 2^16 = 65,536 addresses (65,534 usable)
- `/22`: 2^(32-22) = 2^10 = 1,024 addresses (1,022 usable)

### RFC 1918 Private IP Ranges

Always use these for your internal networks. They're reserved for private use and won't conflict with the public internet.

- `10.0.0.0/8` - Largest private range, 16.7 million addresses
- `172.16.0.0/12` - Medium private range, 1 million addresses
- `192.168.0.0/16` - Smallest private range, 65,536 addresses

### AWS Default Recommendations

When I'm setting up a new VPC, I typically follow this pattern:

- VPC CIDR: `10.0.0.0/16` (gives me 65,536 IPs to work with)
- Public Subnet 1: `10.0.1.0/24` (254 usable IPs)
- Public Subnet 2: `10.0.2.0/24` (254 usable IPs)
- Private Subnet 1: `10.0.10.0/24` (254 usable IPs)
- Private Subnet 2: `10.0.11.0/24` (254 usable IPs)
- EKS Pod CIDR: `100.64.0.0/16` (separate from VPC, plenty of room for pods)

This layout leaves me with plenty of unused CIDR blocks for future growth without having to redesign my network.

### Common CIDR Mistakes to Avoid

- Do not overlap CIDR blocks within the same VPC
- Do not use overlapping ranges when peering multiple VPCs
- Always account for the two reserved addresses (network and broadcast)
- Do not allocate all your address space at once, leave room for growth
- Do not peer VPCs with conflicting CIDR ranges

---

Hope you found this helpful. Happy hosting!
