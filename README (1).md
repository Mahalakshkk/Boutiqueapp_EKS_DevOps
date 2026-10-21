# Boutique App on AWS EKS: Microservices Deployment with Terraform, Docker, Kubernetes and Prometheus/Grafana

A hands-on DevOps project that deploys a containerized **e-commerce microservices application** on **AWS EKS**. The infrastructure is created with **Terraform**, the images are built with **Docker** and stored in **Amazon ECR**, the services run on **Kubernetes**, and the cluster is monitored with **Prometheus and Grafana**.

> The application code is based on Google's open-source **Online Boutique** microservices demo (Apache 2.0). The DevOps work in this repo (infrastructure as code, build/push scripting, Kubernetes deployment, monitoring and troubleshooting) was done by me.

For every command I ran, the problems I hit and how I fixed them, read [PROJECT_HANDBOOK.md](PROJECT_HANDBOOK.md).

---

## Architecture

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform (VPC, EKS cluster, worker nodes) |
| Containerization | Docker (one image per microservice) |
| Image registry | Amazon ECR |
| Orchestration | Kubernetes on Amazon EKS |
| Monitoring | Prometheus + Grafana (Helm chart `kube-prometheus-stack`) |
| CI/CD | Jenkins pipeline (`Jenkinsfile`) |

**Flow:** Terraform creates the cluster, then Docker builds each microservice and pushes it to ECR. Kubernetes pulls those images and runs them, and a load balancer exposes the `frontend` service. Prometheus collects metrics and Grafana shows them.

**Region:** `ap-northeast-1` (Tokyo)  
**Cluster name:** `demo-cluster`

---

## Services deployed

`frontend`, `cartservice`, `checkoutservice`, `currencyservice`, `paymentservice`, `productcatalogservice`, `recommendationservice`, `shippingservice`, `emailservice`, `adservice`, `shoppingassistantservice`, and a `redis-cart` datastore.

---

## Repository structure

```
.
├── EKS-cluster-terraform/     # Terraform files that create the EKS cluster
├── Microservices/
│   ├── src/                   # Source and Dockerfile for each microservice
│   ├── kubernetes-manifests/  # Kubernetes Deployment/Service YAML files
│   └── docker_image_buid_push.sh   # Builds and pushes all images to ECR
├── Monitor.sh                 # Installs Prometheus + Grafana with Helm
├── Jenkinsfile                # CI/CD pipeline definition
├── Outputs/                   # Screenshots of the running project
├── PROJECT_HANDBOOK.md        # Full step-by-step record of this project
└── README.md
```

---

## Prerequisites

- An AWS account with permissions for EKS, EC2, VPC, IAM and ECR
- An Ubuntu EC2 "workstation" with an IAM role attached (this is where the commands are run)
- AWS CLI, Terraform, Docker, kubectl and Helm installed
- A GitHub account

---

## Quick start

> Replace `<ACCOUNT_ID>` with your own 12-digit AWS account ID.

**1. Create the cluster**
```bash
cd EKS-cluster-terraform
terraform init
terraform apply -auto-approve
```

**2. Connect kubectl**
```bash
aws eks --region ap-northeast-1 update-kubeconfig --name demo-cluster
kubectl get nodes
```

**3. Build and push the images to ECR**
```bash
cd ../Microservices
chmod +x docker_image_buid_push.sh
./docker_image_buid_push.sh
```
The image registry address and region inside the script and the manifests must match your own account (`<ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com`).

**4. Deploy to Kubernetes**
```bash
kubectl apply -f kubernetes-manifests/
kubectl get pods
kubectl get svc frontend-external
```
Open `http://<EXTERNAL-IP>` from the last command to see the store.

**5. Install monitoring**
```bash
cd ..
chmod +x Monitor.sh
./Monitor.sh
kubectl patch svc grafana-prometheus -n monitor -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n monitor grafana-prometheus
```
Log in to Grafana at `http://<GRAFANA-EXTERNAL-IP>` with username `admin` and the password printed by the script.

**6. Clean up (to avoid AWS charges)**
```bash
kubectl delete -f Microservices/kubernetes-manifests/
helm uninstall grafana-prometheus -n monitor
cd EKS-cluster-terraform && terraform destroy -auto-approve
```
Then delete the ECR repositories in the ECR console.

---

## Screenshots

<!-- Add a screenshot of the running store here, for example:
### Online store (frontend)
![Online store](Outputs/website.png)
-->

### Grafana: cluster resource usage for the `default` namespace
Dashboard: **Kubernetes / Compute Resources / Namespace (Pods)**. It shows CPU utilisation (from requests and limits), memory utilisation, and CPU usage per boutique pod.

![Grafana CPU and memory overview](Outputs/grafana-cpu-overview.png)

### Grafana: CPU quota and memory usage per pod
Per-pod CPU requests and limits, with memory usage graphs for services such as `adservice`, `cartservice` and `currencyservice`.

![Grafana CPU quota and memory usage](Outputs/grafana-cpu-quota-memory.png)

### Grafana: network bandwidth and packets
Received and transmitted bandwidth and packet rates for every pod in the `default` namespace.

![Grafana network bandwidth](Outputs/grafana-network.png)

---

## Problems solved along the way

| Problem | Cause | Fix |
|---|---|---|
| `apt-get install` returned `404 Not Found` while building an image | A base image used an end-of-life Debian release whose mirrors dropped its security packages | Moved the Dockerfile base image to a current Debian (`bookworm`) |
| `403 Forbidden` when pushing to ECR | The script and manifests still contained the original project's AWS account ID | Replaced it with my own account ID everywhere |
| `Password authentication is not supported for Git operations` | GitHub no longer accepts account passwords for `git push` | Used a Personal Access Token |
| Lost all work after an instance reload | Work only existed on the server | Used `tmux` for long jobs and pushed to GitHub after each step |
| `ImagePullBackOff` risk | Manifest image names or tags not matching ECR | Checked `image:` lines against ECR tags before deploying |

---

## What I learned

- Provisioning an EKS cluster with Terraform and connecting to it with `kubectl`
- Building, tagging and pushing Docker images to Amazon ECR
- Running a multi-service application on Kubernetes and exposing it with a load balancer
- Installing Prometheus and Grafana with Helm and reading cluster dashboards
- Debugging real errors: end-of-life base images, registry permissions and Git authentication
- Controlling cloud cost by cleaning up resources

---

## Credits

Application code: [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) (Apache 2.0).  
DevOps implementation, deployment and documentation: Mahalakshmi.
