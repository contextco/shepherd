# Shepherd - Easily Manage Self-Hosted Deployments 

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
- Optionally deploy the Shepherd agent alongside your application in your customers Kubernetes cluster
- Push upgrades to each deployment with a single button click
- The agent can enforce pre-upgrade backups and enable rollbacks 

### Deployment Monitoring
- Monitor deployment status at the deployment and pod-level
- This reports deployment online/offline status, and currently running version 

## Get Started

Instructions TODO

## More Information
Check out:
- [Website](https://trustshepherd.com)
- [Documentration](https://docs.trustshepherd.com)

## Feedback?
We would love to hear it! Open an issue and let us know, or email us at henry@context.ai
