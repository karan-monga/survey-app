
# SWE 645 - Assignment 2: Student Survey Application

## URLs
- Jenkins Server: `http://34.227.28.156:8080`
- Survey Application: `http://35.196.147.237:80`
- GitHub Repository: https://github.com/karan-monga/survey-app

## Project Overview
This project implements a containerized version of the student survey web application from Assignment 1. The application has been containerized using Docker and deployed to Google Kubernetes Engine (GKE) using a Jenkins CI/CD pipeline. The setup ensures high availability with multiple pods running the application.

## System Architecture
1. **Frontend**: Static HTML served through Nginx web server
2. **Container**: Docker container based on nginx:alpine image
3. **Orchestration**: Google Kubernetes Engine (GKE) cluster with 3 pods
4. **CI/CD**: Jenkins pipeline on AWS EC2
5. **Source Control**: GitHub repository
6. **Container Registry**: Docker Hub

## Detailed Setup Instructions

### 1. AWS EC2 Instance Setup for Jenkins
1. Launch EC2 Instance:
   - Go to AWS Console → EC2 → Launch Instance
   - Name: jenkins-server
   - AMI: Ubuntu Server 22.04 LTS
   - Instance Type: t2.medium
   - Storage: 30 GiB gp2
   - Security Group Configuration:
     ```
     Type        Port    Source
     SSH         22      0.0.0.0/0
     HTTP        80      0.0.0.0/0
     Custom TCP  8080    0.0.0.0/0
     Custom TCP  50000   0.0.0.0/0
     ```

2. Jenkins Installation:
```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Java
sudo apt install openjdk-11-jdk -y

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Set Docker permissions
sudo chmod 666 /var/run/docker.sock

# Get initial Jenkins password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

3. Jenkins Initial Setup:
   - Access Jenkins at `http://[EC2-Public-IP]:8080`
   - Enter initial admin password
   - Install suggested plugins
   - Create admin user
   - Configure Jenkins URL

### 2. Docker Configuration
1. Create Dockerfile:
```dockerfile
# Use the nginx base image
FROM nginx:alpine

# Copy survey.html to be served as index.html
COPY ./survey.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

2. Local testing:
```bash
# Build image
docker build -t karanmonga/survey-app:latest .

# Test locally
docker run -d -p 80:80 karanmonga/survey-app:latest

# Push to Docker Hub
docker login
docker push karanmonga/survey-app:latest
```

### 3. Google Kubernetes Engine (GKE) Setup
1. Create GKE Cluster:
   - Go to Google Cloud Console
   - Navigate to Kubernetes Engine → Clusters → Create
   - Cluster Basics:
     - Name: survey-cluster
     - Zone: us-east1-b
     - Control plane version: 1.27.3-gke.100
   - Node Pool:
     - Number of nodes: 3
     - Machine type: e2-medium
   - Click Create

2. Configure Service Account:
   - Go to IAM & Admin → Service Accounts
   - Create Service Account:
     - Name: jenkins-gke
     - Role: Kubernetes Engine Developer
   - Create and download key (JSON)
   - Save as service-account.json

### 4. Jenkins Pipeline Configuration
1. Required Jenkins Plugins (Manage Jenkins → Plugins):
   - Docker Pipeline
   - Kubernetes CLI
   - Git plugin
   - Google Kubernetes Engine

2. Configure Credentials:
```
Manage Jenkins → Credentials → System → Global credentials
1. Docker Hub:
   - Kind: Username with password
   - ID: docker-token
   - Username: karanmonga
   - Password: [your-dockerhub-token]

```

3. Create Pipeline:
   - New Item → Pipeline
   - Configure:
     - GitHub project: https://github.com/karan-monga/survey-app
     - Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/karan-monga/survey-app.git
     - Branch: */main

### 5. Jenkinsfile Configuration
```groovy
pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'concise-orb-439615-r5'
        DOCKER_HUB_CREDENTIALS = credentials('docker-token')
        DOCKER_IMAGE = 'karanmonga/survey-app'
        CLUSTER_NAME = 'survey-cluster'
        CLUSTER_ZONE = 'us-east1-b'
        GOOGLE_CREDENTIALS = credentials('gcp-service-account')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    sh """
                        echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin
                        docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GC_KEY')]) {
                        sh """
                            gcloud auth activate-service-account --key-file=\$GC_KEY
                            gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${PROJECT_ID}
                            kubectl set image deployment/survey-app-deployment survey-app=${DOCKER_IMAGE}:${BUILD_NUMBER} --record
                        """
                    }
                }
            }
        }
    }
}
```

## Testing and Verification
1. Push code changes to GitHub:
```bash
git add .
git commit -m "Update survey application"
git push origin main
```

2. Monitor Jenkins Pipeline:
   - Go to Jenkins dashboard
   - Click on your pipeline
   - Click "Build Now"
   - Monitor Console Output

3. Verify Deployment:
```bash
# Check pods
kubectl get pods

# Check service
kubectl get service survey-app-service
```

4. Access Application:
   - Get external IP from service
   - Access at `http://35.196.147.237:80`

## Troubleshooting Guide
1. Jenkins Build Issues:
   - Check Docker Hub credentials
   - Verify Docker daemon is running
   - Check Jenkins logs: `sudo tail -f /var/log/jenkins/jenkins.log`

2. GKE Deployment Issues:
   - Verify GCP service account permissions
   - Check pod logs: `kubectl logs [pod-name]`
   - Check deployment status: `kubectl describe deployment survey-app-deployment`

3. Docker Issues:
   - Check Docker permissions: `sudo chmod 666 /var/run/docker.sock`
   - Verify Docker service: `sudo systemctl status docker`

## References
1. Jenkins Documentation: https://www.jenkins.io/doc/
2. Google Kubernetes Engine: https://cloud.google.com/kubernetes-engine/docs
3. Docker Documentation: https://docs.docker.com/
4. Nginx Documentation: https://nginx.org/en/docs/
5. GitHub Actions: https://docs.github.com/en/actions

## Author
- Karan Monga
G01472559
