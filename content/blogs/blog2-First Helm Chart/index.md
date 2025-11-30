+++
date = '2025-10-23T20:36:07-04:00'
draft = false
title = 'How to Create Your First Helm Chart'
+++


If you're working with Kubernetes, you've probably noticed that managing YAML files across different environments can get messy quickly. That's where Helm comes in. Helm is a package manager for Kubernetes that helps you define, install, and manage applications using something called charts. In this guide, we'll walk through creating your first Helm chart step by step.

## What is a Helm Chart?

A Helm chart is essentially a collection of files that describe Kubernetes resources. Think of it as a template for your application that you can reuse across multiple environments like development, staging, and production. Instead of maintaining separate YAML files for each environment, you create one chart and customize it with different values.

## Prerequisites

Before we start, make sure you have:

- Helm installed on your machine
- Access to a Kubernetes cluster
- Basic understanding of Kubernetes concepts like Deployments and Services

## Step 1: Create Your First Chart

Creating a new Helm chart is straightforward. Open your terminal and run:

```bash
helm create my-first-chart
```

This command generates a directory called `my-first-chart` with a standard structure. Let's explore what's inside.

## Step 2: Understanding the Chart Structure

When you navigate into the newly created directory, you'll see several files and folders:

```bash
my-first-chart/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── _helpers.tpl
    └── NOTES.txt
```

Here's what each component does:

**Chart.yaml**: This file contains metadata about your chart like its name, version, and description. It's like the identity card for your Helm chart.

**values.yaml**: This is where you define default configuration values. These values can be referenced in your templates and easily overridden during installation.

**templates/**: This directory holds all your Kubernetes manifest files. Helm processes these files through a templating engine before sending them to Kubernetes.

**charts/**: If your chart depends on other charts, they go here.

## Step 3: Customize Chart.yaml

Open the `Chart.yaml` file and update it with your chart details:

```yaml
apiVersion: v2
name: my-first-chart
description: My very first Helm chart
type: application
version: 0.1.0
appVersion: "1.0.0"
```

The `apiVersion: v2` is used for Helm 3, while `type: application` indicates this chart deploys an application (as opposed to a library chart).

## Step 4: Define Your Values

The `values.yaml` file lets you parameterize your templates. Here's a simple example:

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.21.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
```

These values will be injected into your templates, making your chart flexible and reusable.

## Step 5: Create Templates

Now comes the fun part. Templates are regular Kubernetes YAML files with special template directives. Let's look at a simple deployment template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
```

Notice the template directives enclosed in double curly braces like `{{ .Values.replicaCount }}`. These get replaced with actual values from your `values.yaml` file when you install the chart.

## Step 6: Test Your Chart

Before installing, it's wise to validate your chart. Run this command from your chart directory:

```bash
helm lint .
```

This checks for errors and formatting issues. To see what Kubernetes manifests will be generated without actually installing anything, use:

```bash
helm template .
```

You can also do a dry run:

```bash
helm install --dry-run --debug my-release ./my-first-chart
```

## Step 7: Install Your Chart

Once everything looks good, install your chart:

```bash
helm install my-release ./my-first-chart
```

Here, `my-release` is the name of your release. Helm will generate all the Kubernetes resources and deploy them to your cluster.

To verify the installation:

```bash
helm list
kubectl get all
```

## Step 8: Update and Manage Your Release

If you need to make changes, update your chart files and run:

```bash
helm upgrade my-release ./my-first-chart
```

To roll back to a previous version:

```bash
helm rollback my-release
```

And when you're done, clean up with:

```bash
helm uninstall my-release
```

## Conclusion

Congratulations! You've just created your first Helm chart. We covered the basic structure of a chart, how to define values and templates, and how to install and manage releases. Helm charts might seem complex at first, but once you understand the basics, they become an invaluable tool for managing Kubernetes applications across multiple environments.

The key takeaway is that Helm lets you write your Kubernetes manifests once and reuse them everywhere by simply changing values. This makes your deployments more consistent, maintainable, and less error-prone. As you get more comfortable, you can explore advanced features like chart dependencies, hooks, and custom functions to make your charts even more powerful.