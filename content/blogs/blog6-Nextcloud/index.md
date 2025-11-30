+++
date = '2025-10-23T20:36:07-04:00'
draft = false
title = 'Nextcloud redirect issue fixed!'
+++

Hello world! I recently decided to deploy Nextcloud on my home server using Kubernetes. I love self-hosting, and using the official Helm chart seemed like the cleanest way to go.

Everything seemed to install perfectly, but the moment I tried to log in, I hit a wall. I would type my password, click "Log in," and… nothing. The button just kept spinning. If I refreshed the page, I’d get stuck in a weird redirect loop or see an "Untrusted Domain" error. It was driving me crazy!

After a lot of digging and debugging, I figured out it was a reverse proxy issue. Nextcloud didn't realize it was sitting behind an ingress controller, so it was getting confused about `http` vs `https`.

If you are facing the same thing, don’t worry, I’ve got the fix right here. Here is how I got it working.

---

### Step 1: Getting the Official Charts
First things first, I added the official Nextcloud repository. I prefer using the official sources rather than third-party ones just to stay close to the developers' updates.

```bash
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
```

### Step 2: The Problem I Ran Into
Here is exactly what was happening to me. I deployed the standard chart, and Nextcloud was running, but it didn't know it was behind an Ingress controller.

Because my SSL termination happens at the Ingress level (and not inside the Nextcloud pod itself), Nextcloud thought I was trying to access it via insecure HTTP. It kept trying to redirect me to internal IPs or insecure URLs, and my browser just blocked it.

### Step 3: The Config That Fixed It
To fix this, I had to explicitly tell Nextcloud: "Hey, trust the proxy, and pretend you are always on HTTPS."

I created a `values.yaml` file and added a specific `configs` section. This acts like a patch that injects a PHP configuration file right into Nextcloud.

Here is the exact custom config I used.

*> **Note:** You'll need to replace `nextcloud-mysite.duckdns.org` with your actual domain.*

```yaml
nextcloud:
  host: nextcloud-mysite.duckdns.org
  
  # This is the magic part that fixed my login loop!
  configs:
    proxy.config.php: |-
      <?php
      $CONFIG = array (
        // Trust the Ingress Controller IPs
        // I added these ranges to cover standard K8s Pod networks
        'trusted_proxies' => array(
          0 => '10.0.0.0/8',
          1 => '172.16.0.0/12',
          2 => '192.168.0.0/16',
        ),
        // Force Nextcloud to use my external domain for redirects
        'overwritehost' => 'nextcloud-mysite.duckdns.org',
        // Force Nextcloud to generate HTTPS links
        'overwriteprotocol' => 'https',
        // Ensure CLI commands (like cron jobs) use the correct URL
        'overwrite.cli.url' => 'https://nextcloud-mysite.duckdns.org',
      );

ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: nextcloud-mysite.duckdns.org
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

### Step 4: Launching It
Once I had that file saved as `nextcloud-values.yaml`, I simply installed the chart pointing to it:

```bash
helm install nextcloud nextcloud/nextcloud -f nextcloud-values.yaml
```

I waited a minute for the pods to spin up:
```bash
kubectl get pods -w
```

And that was it! I went to my URL, and the login worked instantly. No more spinning wheel, no more loops.

### A Quick Troubleshooting Tip
If you use this config and still see an **"Untrusted Domain"** error, double-check that the `overwritehost` line in the YAML matches the URL in your browser exactly. It's super picky about that!

I hope this quick guide saves you the hours of troubleshooting it took me. 

Happy hosting!
