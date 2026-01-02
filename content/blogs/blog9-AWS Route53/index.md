+++
date = '2025-12-19T17:03:00-05:00'
draft = false
title = 'AWS Route 53 Quick Reference Guide'
+++


Alright, let's break down Route 53 in a way that makes sense for us DevOps folks. Think of it as your DNS traffic cop for AWS.

## What's Route 53 All About?

Route 53 is AWS's DNS service (and yes, "53" is the DNS port number). It handles domain registration, routes your internet traffic to the right place, and keeps tabs on whether your stuff is actually working. Pretty cool, right?

**Key facts:**
- One of AWS's most reliable services (seriously, they claim 100% uptime)
- Works with any AWS resource (EC2, ALBs, S3, CloudFront, etc.)
- Can handle on-premises infrastructure too
- Global distribution means your DNS queries are super fast

## Hosted Zones: Your DNS Home Base

A hosted zone is basically a container that holds all your DNS records for a domain.

**Public Hosted Zone**
Handles traffic coming from the internet. Use this when you need publicly accessible resources.

**Private Hosted Zone**
Lives inside your VPC and handles DNS for your internal resources. Perfect for stuff you don't want exposed to the internet.

When you create a hosted zone, Route 53 automatically creates NS (name server) and SOA (start of authority) records. You get four unique name servers for delegation.

## DNS Record Types You'll Actually Use

| Record Type | What It Does | Example |
|---|---|---|
| **A** | Maps domain to IPv4 address | example.com → 192.0.2.1 |
| **AAAA** | Maps domain to IPv6 address | example.com → 2001:0db8::1 |
| **CNAME** | Points domain to another domain | blog.example.com → example.com |
| **MX** | Routes email to mail servers | Points to your mail server |
| **TXT** | Holds arbitrary text data | SPF, DKIM, domain verification |
| **NS** | Specifies authoritative name servers | Created automatically |
| **SOA** | Start of Authority record | Created automatically |

### Alias Records (Route 53's Secret Weapon)

Alias records are like CNAME but better. They're AWS-specific and let you point to AWS resources without weird DNS issues.

**Why they're awesome:**
- Can be used at the root domain (example.com, not just subdomains)
- No extra DNS lookup charges
- Work with ALBs, CloudFront, S3, and other AWS resources
- Return an A record to clients (server-side resolution)

```yaml
example.com:
  Type: A
  AliasTarget:
    HostedZoneId: Z35SXDOTRQ7X7K  # ALB Zone ID
    DNSName: my-alb-123456.us-east-1.elb.amazonaws.com
    EvaluateTargetHealth: true
```

## The 8 Routing Policies (Pick Your Strategy)

### 1. Simple Routing
Default option. Send traffic to a single resource. No frills.
- Use when: You've got one resource and don't need failover
- Example: Single EC2 instance

### 2. Weighted Routing
Split traffic based on percentages you set.
- Use when: A/B testing, gradual migrations, or blue-green deployments
- Example: 70% to us-east-1, 30% to eu-west-1

```yaml
Resource1:
  Weight: 70
Resource2:
  Weight: 30
```

### 3. Latency Routing
Route users to the resource with the lowest latency for them.
- Use when: Multi-region setup where response time matters
- Example: EU users hit eu-west-1, US users hit us-east-1

### 4. Failover Routing (Active-Passive)
Primary resource handles traffic. Secondary takes over if primary goes down.
- Use when: Simple HA setup (not load balancing)
- Example: Primary database in us-east-1, failover in us-west-2

### 5. Geolocation Routing
Route based on where your users actually are (continent, country, state).
- Use when: Content delivery, compliance, or geo-specific data
- Example: EU users get EU data center, compliance restrictions, etc.

### 6. Geoproximity Routing
Combines user location and resource location with optional bias.
- Use when: You want geographic preference but with flexibility
- Bias adjustments expand or shrink your service areas

### 7. Multivalue Answer Routing
Return up to 8 random healthy records at once.
- Use when: Simple load balancing without complexity
- Not a replacement for actual load balancers
- Each record gets its own health check

### 8. IP Based Routing
Route traffic based on the client's IP address (CIDR blocks).
- Use when: You know the IP ranges and want custom routing
- Use case: Different treatment for your corporate office vs public traffic

## Health Checks: Making Sure Everything's Actually Healthy

Health checks monitor your resources and automatically redirect traffic if something's broken.

### Three Types of Health Checks

**Endpoint Health Checks**
Monitor actual endpoints (HTTP/HTTPS, TCP, etc.)
- Configure intervals: Standard (30 seconds) or Fast (10 seconds)
- Set failure threshold before marking unhealthy
- Can search for specific text in responses

```yaml
HealthCheck:
  Type: HTTP
  IPAddress: 192.0.2.1
  Port: 80
  Path: /health
  RequestInterval: 30
  FailureThreshold: 3
  SearchString: "OK"
```

**Calculated Health Checks**
Aggregate the status of other health checks
- Combine multiple health check results
- Great for: Complex availability logic

**CloudWatch Health Checks**
Use CloudWatch alarms as health check sources
- Monitor any CloudWatch metric
- Trigger failover based on custom metrics

### Key Health Check Features

- Global monitoring from multiple AWS edge locations (prevents false positives)
- Automatic CloudWatch metrics integration
- Custom headers and request configuration
- Text string matching in responses
- SNS notifications and alarms on status change

## Route 53 Resolver: Your AWS DNS Middleman

Handles DNS resolution both ways between AWS and on-premises.

**Inbound Endpoints**
On-premises systems query Route 53 for AWS resources

**Outbound Endpoints**
AWS resources query Route 53 for on-premises DNS

Perfect for hybrid environments where you need seamless DNS.

## Common Patterns You'll Actually Use

### Blue-Green Deployment
Use weighted routing, slowly shift traffic from blue to green:

```yaml
BlueRecords:
  Weight: 100
GreenRecords:
  Weight: 0
  # Gradually increase Green weight, decrease Blue weight
```

### Regional Failover
Latency routing handles primary, failover takes secondary:

```yaml
Primary:
  Region: us-east-1
  HealthCheck: primary-hc
  SetIdentifier: primary
Secondary:
  Region: us-west-2
  HealthCheck: secondary-hc
  SetIdentifier: secondary
```

### Traffic Distribution
Weighted routing for distributing load across regions:

```yaml
RegionA:
  Weight: 40
RegionB:
  Weight: 40
RegionC:
  Weight: 20
```

## DNS Resolution Flow (Quick Mental Model)

1. User asks browser: "What's the IP for example.com?"
2. Browser queries recursive resolver (ISP's DNS)
3. Resolver queries .com authoritative servers
4. Gets Route 53 name server addresses
5. Queries Route 53 with your routing policy
6. Route 53 applies logic (latency, weight, geo, etc.)
7. Returns the right IP address
8. Browser connects to that IP

## Things That'll Save You Time

**Enable Health Check CloudWatch Alarms**
Get SNS notifications before your users notice problems

**Use Alias Records**
Save money (no extra charges) and avoid CNAME issues at root

**Set Up Traffic Flow** (If you need it)
Visual editor for complex routing policies. Easier than managing individual records.

**Tag Your Resources**
Makes cleanup and organization so much easier

**Monitor Resolver Query Logs**
Debug DNS issues without tearing your hair out

## Important Gotchas

- CNAME records can't be used at domain root (use Alias instead)
- Health checks run from multiple locations (prevents false positives but means you need proper metrics)
- Private hosted zones need enableDnsHostnames and enableDnsSupport on your VPC
- Failover routing only works in public hosted zones
- Default limit is 200 health checks (request increase if needed)
- Health check intervals are fixed (30 or 10 seconds, nothing in between)

## Quick Pricing Note

Route 53 is cheap. You pay per hosted zone and per query (after free tier). Health checks add a small cost. Domain registration is separate and varies by TLD.

---

Hope you found this helpful. Happy hosting!