---
date: 2025-12-19T17:03:00-05:00
draft: false
title: "Network Debugging Guide"
summary: "A practical guide to systematically troubleshooting network issues in DevOps environments."
---

Network stuff breaks. It always does. And when it does, you need a way to figure out what's actually wrong instead of just guessing. That's what this is for.

## Quick Reality Check

Before you do anything fancy, just check if your interface is even there:

```bash
ip a
```

Look for **UP** and **LOWER_UP** flags. No IP? No flags? That's your answer right there. Bring it up:

```bash
sudo ip link set eth0 up
```

Need a DHCP refresh?

```bash
sudo systemctl restart networking
```

Done? Ok, moving on...

## The Actual Flow: Do This in Order

I'm going to give you the exact sequence I follow when something's broken. This works because it eliminates the biggest problems first before you waste time on DNS or firewall.

### 1: Can You Talk to Your Gateway?

Your gateway is like the door to the outside world. If the door's locked, everything else is meaningless.

```bash
ping -c 3 192.168.1.1
```

Replace that IP with your actual gateway. Find it here if you're not sure:

```bash
ip route show
```

Look for the line that says **default via** something. That IP is your gateway.

If the ping works, you've got local connectivity. If it doesn't, you've got a network configuration issue, bad VLAN setup, or the gateway address is just wrong.

### 2: Can You Reach Anything Out There?

Now ping something on the internet by its IP address. I use Google's DNS:

```bash
ping -c 3 8.8.8.8
```

This test tells you if routing actually works. If your gateway ping works but this fails, you've got a firewall blocking you, a routing loop, or your ISP is having a day.

### 3: Does DNS Actually Resolve?

```bash
dig google.com
```

Or if dig isn't installed (which is weird but happens):

```bash
nslookup google.com
```

If this hangs or fails, check what DNS servers you're pointing at:

```bash
cat /etc/resolv.conf
```

You should see actual nameserver entries. Not seeing them? That's the problem.

```bash
cat /etc/netplan/01-netcfg.yaml
```

Or check your NetworkManager config depending on your setup. Make sure DNS is actually configured.

### 4: Is Your Firewall the culprit?

I check this when everything above works but traffic still isn't flowing to specific ports or destinations.

If you're using UFW:

```bash
sudo ufw status verbose
```

Using iptables directly:

```bash
sudo iptables -L -n -v
```

Or firewalld:

```bash
sudo firewall-cmd --list-all
```

Look for DROP or REJECT rules on outbound traffic. If you find them and you weren't expecting them, that's your culprit.

## The Deep Dive: When Simple Doesn't Work

Sometimes the basics all pass and you still can't reach what you need. Here's where I go next.

### Trace the Path

See exactly where your packets are going (and where they're dying):

```bash
mtr -rw 8.8.8.8
```

This runs a continuous MTR trace. Look for any hops that show asterisks or really high packet loss. That's where things are breaking down.

If you want old school traceroute:

```bash
traceroute -m 20 8.8.8.8
```

The **m 20** means check up to 20 hops. If it stops early, something upstream is blocking ICMP.

### Check for Packet Loss and Latency Issues

Sometimes the network "works" but it's borderline unusable:

```bash
ping -c 100 8.8.8.8
```

Look at the packet loss percentage. Zero is ideal. Anything above 5% is a problem worth investigating. Latency varies wildly depending on your setup, but consistent increases over time usually mean congestion or hardware issues.

### Look at Interface Stats

Sometimes packets are just dying on the interface itself:

```bash
ip -s link show eth0
```

Watch for:

- **RX errors** or **TX errors** that keep increasing (hardware problem or duplex mismatch)
- **RX dropped** or **TX dropped** increasing (buffer problems, usually means load issue)
- **RX overrun** (interface is getting more traffic than it can handle)

### Test Specific Ports

Maybe the network is fine but the service isn't listening:

```bash
nc -zv your-host 80
```

This tells you if port 80 is actually open and listening. For SSH:

```bash
nc -zv your-host 22
```

Or if you don't have netcat (unlikely, but):

```bash
telnet your-host 80
```

Hit Ctrl+C when you're done.

## Containers and Kubernetes Make It Weird

If you're running this stuff in containers, network troubleshooting gets an extra layer of fun.

### Check Inside the Container

Get into your container and run the same commands:

```bash
docker exec -it container-name bash
```

Then run all the normal tools. If things work on the host but not in the container, it's a networking bridge issue or container network configuration.

### Check the CNI (Container Network Interface)

If you're in Kubernetes:

```bash
kubectl get pods -A
```

Look at your CNI plugin pods. Are they running? Are they restarted recently? Check logs:

```bash
kubectl logs -n kube-system -l k8s-app=flannel
```

Replace flannel with your actual CNI (calico, weave, whatever you use).

### Service DNS In Kubernetes

Kubernetes DNS is special. Test it:

```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

If that doesn't resolve, your CoreDNS is probably broken.

## When You're Desperate

You've tried everything above and things still feel weird. Here's what I do.

### Restart Everything

Start with just the network:

```bash
sudo systemctl restart networking
```

If you're on a system using NetworkManager:

```bash
sudo systemctl restart NetworkManager
```

Then verify:

```bash
ping -c 3 8.8.8.8
```

### Check System Logs

```bash
journalctl -u networking -n 50
```

Or for NetworkManager:

```bash
journalctl -u NetworkManager -n 50
```

Look for error messages. They're usually pretty obvious.

### Verify Your DNS Config Is Sane

This catches so many weird issues:

```bash
systemd-resolve --status
```

This shows what DNS servers are actually active. If nothing's listed or it shows localhost with no upstream servers, that's why nothing resolves.

### Check MTU Issues

Sometimes packets are getting fragmented wrong:

```bash
ip link show eth0
```

Look for the **mtu** value. Standard is 1500. If it's different and you don't know why, that's often a problem in weird network setups:

```bash
sudo ip link set dev eth0 mtu 1500
```

## The Quick Checklist

When you're in a rush and need to know if it's a network problem:

1. Interface up? **ip a**
2. Gateway reachable? **ping [gateway-ip]**
3. External IPs work? **ping 8.8.8.8**
4. DNS resolves? **dig google.com**
5. Specific port open? **nc -zv host port**
6. Firewall allowing it? **ufw status** or **iptables -L**

If all six pass and you still can't reach something, it's probably on the other end, not your machine.

## Real World Scenarios I've Seen

**"Everything pings but my service can't reach the database"**

Usually a firewall rule on the database server, or the service is trying to use a hostname that doesn't resolve inside the container. Test the connection from the service itself, not from your laptop.

**"Network was working, then I changed nothing and it stopped"**

Probably a DHCP lease expired and the renewal failed. Or someone rebooted the gateway. Or a VLAN got misconfigured upstream. Check your gateway connectivity first.

**"It works when I ping but the actual connection times out"**

ICMP and TCP might be different firewall rules. Test with the actual protocol. For a web server, use curl:

```bash
curl -v http://destination:port
```

**"DNS works from my laptop but not from the container"**

Container DNS configuration is separate. Check the container's /etc/resolv.conf. If it's empty or weird, your container runtime needs to pass DNS config properly.

**"Traffic is really slow but everything shows 0 packet loss"**

Could be latency or throughput issues. Run an iperf test if you need real numbers:

```bash
iperf3 -c destination-host
```

But honestly, slow + 0 loss usually means congestion or a misconfigured route with extra hops.

## Tools That Actually Help

| When You Need To           | Command                             |
| -------------------------- | ----------------------------------- |
| See all interfaces and IPs | `ip a`                              |
| Check routing              | `ip route show`                     |
| See DNS servers being used | `systemd-resolve --status`          |
| Verify DNS resolution      | `dig domain.com`                    |
| Ping something             | `ping -c 3 host`                    |
| Test a port                | `nc -zv host port`                  |
| Trace packet path          | `mtr -rw host`                      |
| See interface errors       | `ip -s link show eth0`              |
| Check firewall (UFW)       | `sudo ufw status verbose`           |
| Check firewall (iptables)  | `sudo iptables -L -n -v`            |
| Look at recent logs        | `journalctl -n 50`                  |
| Restart network            | `sudo systemctl restart networking` |

## Conclusion

Network troubleshooting sucks at first. You don't know what the heck is happening or where to even start. But if you have a set of steps, it makes things easier. The key is doing it in order.

Hope you found this helpful. Happy hosting!
