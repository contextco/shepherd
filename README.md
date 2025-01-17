# Shepherd - Easily Manage Self-Hosted Deployments

![Github Card (3)](https://github.com/user-attachments/assets/1658fc7b-e2d6-460f-bb40-0cb63eb532b5)

Shepherd helps software vendors easily manage self-hosted deployments. The product is MIT licensed, and provides:

- A simplified deployment process requiring less time and expertise. Create Helm charts in minutes for production-ready deployment to any customer VPC, on-prem, or airgapped environment
- Automated deployment upgrades that reduce the rate of human errors, providing rollbacks and enforced backups. This improves deployment version consistency by reducing the effort for each upgrade
- Deployment health monitoring, to identify errors before customers do

[![YouTube Demo Video](https://img.youtube.com/vi/pelVQx_zHJc/0.jpg)](https://www.youtube.com/watch?v=pelVQx_zHJc)

## Product Overview

### Deployment

- Create Helm charts that enable easy deployment to customer Kubernetes clusters
- Define your application in the Shepherd web UI, providing key parameters: docker images, environment variables, and ports
- Optionally include the Shepherd agent in the Helm chart to enable automated upgrades and depoyment health monitoring
- Publish application versions to a Shepherd Helm repository
- Share per-deployment documentation pages with each of your customers, with instructions for them to download, configure, and run the generated Helm chart

### Upgrades

- Optionally deploy the Shepherd agent alongside your application in your customer's Kubernetes cluster
- Push upgrades to each deployment with a single button click
- The agent can enforce pre-upgrade backups and enable rollbacks

### Deployment Monitoring

- Monitor deployment status at the deployment and pod-level
- This reports deployment online/offline status, and currently running version 

## Components

The Shepherd application consists of three main components:

1. **Web UI (./web)** - A Ruby on Rails application that provides:
   - The main web interface for managing deployments
   - Configuration of applications and their deployment parameters
   - Deployment monitoring dashboard
   - Customer documentation pages

2. **Sidecar Service (./web/sidecar)** - A Go binary that:
   - Integrates with the Rails app via gRPC
   - Handles Helm chart generation
   - Manages the packaging and publishing of Helm charts into a Helm repository

3. **Agent (./agent)** - A lightweight Go binary that:
   - Gets deployed within customer Kubernetes clusters
   - Enables automated version upgrades
   - Reports deployment health metrics back to Shepherd via gRPC
   - Manages pre-upgrade backups and rollbacks
   - Sends regular heartbeats to maintain connection status

The Web UI and Sidecar run in your environment, while the Agent runs within your customers' deployments to enable the upgrade and monitoring capabilities.

## More Information

Check out:

- [Website](https://trustshepherd.com)
- [Documentation](https://docs.trustshepherd.com)

## Feedback?

We would love to hear it! Open an issue and let us know, or [email us](mailto:henry@trustshepherd.com)
