+++
date = '2025-08-29T20:36:07-04:00'
draft = false
title = 'Getting Started with GitHub Actions'
+++

Hey there! If you've been wondering what all the fuss is about GitHub Actions, you're in the right place. I'm going to walk you through this amazing feature that completely changed how I handle automation in my projects.

## What Exactly is GitHub Actions?

So here's the thing: GitHub Actions is basically your personal automation buddy that lives right inside your GitHub repository. It's a feature that lets you write custom automated workflows to run whenever something happens in your repo. Think of it as a robot that does your bidding whenever you push code, open a pull request, or even on a schedule you set up.

I remember when I first started using GitHub Actions, I was coming from managing Jenkins servers and writing complicated pipeline scripts. GitHub Actions felt like a breath of fresh air because everything was integrated directly into my repository. No extra servers to maintain, no complex setup. Just pure automation living alongside your code.

## The Key Concepts You Need to Know

Before we dive into actually building workflows, let me break down the main concepts. Don't worry if it seems like a lot at first, I'll explain each piece and it'll all click together.

### Workflows

A workflow is basically a complete automated process. You define it using a YAML file and store it in your repo under the `.github/workflows` directory. Think of it as your blueprint for automation. The workflow contains all the instructions for what should happen and when.

### Events

Events are the triggers that kick off your workflow. Something happens in your GitHub repository or even outside of it, and boom, your workflow starts running. Some common events I use all the time are:

- **push**: Triggers when someone pushes code to your repository
- **pull_request**: Triggers when someone opens or updates a pull request
- **schedule**: Lets you run workflows on a schedule, like a cron job
- **workflow_dispatch**: Allows you to manually trigger a workflow from the UI

You can get pretty specific with these triggers too. For example, you can say "only run this when someone pushes to the main branch" or "only when certain files change". That's the kind of control I love.

### Jobs

Jobs are collections of steps, and here's the cool part: they run in parallel by default. So if you have multiple jobs, they'll all start at the same time unless you tell them otherwise. You can also make jobs wait for other jobs to finish using the `needs` keyword. This is super useful when you have dependencies between different parts of your workflow.

### Steps

Steps are the individual tasks within a job. Each step is a single command or action that gets executed in order. Steps can either run a script you write (using bash, Python, whatever you want) or use a pre built action from the GitHub Marketplace.

### Actions

Actions are reusable blocks of code that do specific things. GitHub provides a bunch of official actions that are super helpful, and the community has created thousands more. You can find actions for setting up Node.js, running tests, deploying to cloud providers, or basically anything else you can imagine.

I use the `actions/checkout` action in basically every workflow because it checks out your code so your job can access it. It's one of those essential actions that's just always there.

### Runners

A runner is the machine that actually executes your workflow. GitHub provides hosted runners (ubuntu, windows, macos) that you can use for free if your repository is public. If you need more control or privacy, you can set up self hosted runners on your own infrastructure. For most of my projects, the GitHub hosted runners work perfectly fine.

## A Real World Example: CI with Docker and Security Scanning

Let me show you a workflow that I actually use in production. This one handles building and pushing Docker images while running security scans. It's what I use with GitOps deployments, and it covers a lot of real world concerns like testing, code quality, security, and containerization.

First, create this file in your repo:

```
.github/
  workflows/
    ci-build-push.yml
```

Here's the complete workflow:

```yaml
name: CI - Build & Push Image (GitOps) # Descriptive workflow name

on: # Define when this workflow runs
  push: # Trigger on code pushes
    branches:
      - main # Only for the main branch
  pull_request: # Also run on pull requests

jobs:
  build: # Single job that does everything
    runs-on: ubuntu-latest # Use Ubuntu runner

    steps:
      - uses: actions/checkout@v4 # Clone your repository code

      - uses: actions/setup-node@v4 # Install Node.js runtime
        with:
          node-version: 20 # Use Node version 20

      - run: npm ci # Clean install of dependencies (better than npm install for CI)

      - run: npm test # Run all unit tests to catch bugs early

      - uses: SonarSource/sonarqube-scan-action@v2 # SAST: Static Application Security Testing
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }} # Your SonarQube security token (keep it secret!)
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }} # Your SonarQube server URL

      - uses: aquasecurity/trivy-action@v0.24.0 # Scan for filesystem vulnerabilities
        with:
          scan-type: fs # Scan the filesystem for vulnerabilities
          severity: HIGH,CRITICAL # Only fail on high and critical severity issues
          exit-code: 1 # Fail the job if critical issues are found

      - uses: docker/login-action@v3 # Login to Docker registry (Docker Hub in this case)
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }} # Your Docker Hub username from secrets
          password: ${{ secrets.DOCKERHUB_TOKEN }} # Your Docker Hub token from secrets

      - uses: docker/build-push-action@v5 # Build and push Docker image
        with:
          push: true # Push the built image to the registry
          tags: | # Tag the image with multiple tags
            username/app:${{ github.sha }} # Use commit SHA as tag for unique identification
```

This workflow is a complete CI/CD pipeline. Here's what happens step by step: first, it checks out your code and sets up Node.js. Then it installs dependencies and runs your tests. Next, it does a SAST scan using SonarQube to check for code quality issues. After that, Trivy scans your filesystem for known vulnerabilities. If everything passes, it logs into Docker Hub and builds your Docker image, tagging it with the commit SHA. This makes it GitOps friendly because each image is uniquely identifiable by its commit.

The really powerful part here is using `${{ github.sha }}` as the image tag. This means each commit gets a unique Docker image, which is perfect for GitOps workflows where you can reference exact versions in your deployment manifests.

## Using Secrets to Keep Things Safe

GitHub helps you with Secrets. You can set them in your repository settings under "Secrets and variables". Then you can access them in your workflow like this:

```yaml
- name: Deploy to production # Step name
  run: deploy.sh # Run deployment script
  env: # Define environment variables
    API_KEY: ${{ secrets.MY_API_KEY }} # Reference secret API key
    WEBHOOK_URL: ${{ secrets.WEBHOOK_URL }} # Reference secret webhook URL
```

The secrets are masked in the logs too, so even if someone has access to your workflow runs, they can't see the actual values. 


## Viewing Your Workflow Results

After you've pushed your workflow file and triggered it, you can see what's happening by going to your repository and clicking on the "Actions" tab. You'll see all your past workflow runs there. Click on one and you can see the detailed logs of what happened at each step.

## Tips from My Experience

Here are some things I've learned along the way:

**Use the GitHub Marketplace**: Before you write custom scripts, check the Marketplace. Someone probably already created an action for what you need.

**Specify the Action Versions**: Always pin actions (@v4, @v2, or commit SHA) to avoid breaking changes.

**Resource Limits**: GitHub-hosted runners have CPU, memory, and runtime constraints. For heavy builds, consider self-hosted runners or split jobs into smaller steps.

**Use descriptive step names**: When you run a workflow, those step names show up in the logs. Make them clear so you (and your team) know what's happening.

**Exit Codes**: Steps with non-zero exit code fail the job. Use exit-code in actions like Trivy intentionally. Use "continue-on-error" only for optional steps.

## Wrapping Up

GitHub Actions is honestly one of my favorite tools in the DevOps toolkit. It's powerful, flexible, and integrated directly into the platform you're already using. The fact that you can automate basically anything right from your repository is just amazing.

Whether you're running tests, building Docker images, deploying applications, or just automating repetitive tasks, GitHub Actions has got you covered. And the best part? For public repositories, it's completely free.

Hope you found this helpful. Happy hosting!