# EKS CI/CD Project

This project is a demonstration of a CI/CD pipeline for a simple web application deployed to an Amazon EKS cluster. The infrastructure is provisioned using Terraform, and the CI/CD pipeline is managed by GitHub Actions.

## Project Purpose

The main goal of this project is to showcase a complete end-to-end CI/CD workflow for a containerized application on Kubernetes. It's designed as a learning resource and a portfolio piece for DevOps engineers who want to demonstrate their skills in:

-   **Infrastructure as Code (IaC):** Using Terraform to provision and manage all the necessary AWS resources.
-   **Kubernetes:** Deploying and managing applications on an EKS cluster.
-   **CI/CD:** Automating the build, test, and deployment process with GitHub Actions.
-   **Containerization:** Using Docker to package the application.
-   **Helm:** Using Helm to package and deploy the application on Kubernetes.

## Architecture

The project has the following architecture:

-   **AWS:** The cloud provider used for all the infrastructure.
-   **Terraform:** Used to provision the following AWS resources:
    -   VPC, subnets, and other networking components.
    -   EKS cluster.
    -   ECR registry to store the Docker images.
    -   IAM roles and policies for the EKS cluster and GitHub Actions.
    -   A self-hosted GitHub Actions runner on an EC2 instance.
-   **GitHub Actions:** The CI/CD platform used to automate the following steps:
    -   Build the Docker image.
    -   Push the Docker image to ECR.
    -   Deploy the application to the EKS cluster using Helm.
-   **Docker:** Used to containerize the simple web application.
-   **Helm:** Used to package and deploy the web application to the EKS cluster.
-   **Simple Web Application:** A basic HTML application served by Nginx.

## Project Structure

The project is organized into the following directories:

-   `app`: Contains the source code for the simple web application, including the `Dockerfile`.
-   `deployments`: Contains the Helm chart for deploying the application.
-   `infra`: Contains all the Terraform code for provisioning the AWS infrastructure.
-   `scripts`: Contains helper scripts for deployment and for bootstrapping the GitHub Actions runner.
-   `.github/workflows`: Contains the GitHub Actions workflow file.

## How to Use

To use this project, you will need to have the following prerequisites:

-   An AWS account.
-   Terraform installed.
-   kubectl installed.
-   Helm installed.
-   A GitHub account and a personal access token with the `repo` scope.

### 1. Clone the repository

```bash
git clone https://github.com/<your-github-username>/k8s-app-project.git
cd k8s-app-project
```

### 2. Configure the environment variables

Create a `prod.tfvars` file in the `infra` directory with the following content:

```
region        = "us-east-1"
project_name  = "k8s-app-project"
repo_owner    = "<your-github-username>"
repo_name     = "k8s-app-project"
runner_labels = "self-hosted,linux,x64"
```

You will also need to create an SSM parameter in the AWS Systems Manager Parameter Store with your GitHub personal access token. The parameter should be named `/gha/github-pat` and should be of type `SecureString`.

### 3. Provision the infrastructure

```bash
cd infra
terraform init
terraform apply -var-file="prod.tfvars"
```

This will provision all the necessary AWS resources, including the EKS cluster, ECR registry, and the self-hosted GitHub Actions runner.

### 4. Deploy the application

Once the infrastructure is provisioned, the GitHub Actions workflow will be triggered automatically. The workflow will build the Docker image, push it to ECR, and deploy the application to the EKS cluster.

You can monitor the progress of the workflow in the "Actions" tab of your GitHub repository.

### 5. Access the application

Once the deployment is complete, you can access the application by getting the hostname of the ingress:

```bash
kubectl -n custom-nginx get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

## Conclusion

This project provides a solid foundation for building a CI/CD pipeline for a containerized application on Kubernetes. It can be extended and customized to fit more complex scenarios.
