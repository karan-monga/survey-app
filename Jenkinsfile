pipeline {
    agent {
        kubernetes {
            label 'k8s-jenkins-agent' // Must match your pod template label
            defaultContainer 'jnlp'
        }
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/karan-monga/survey-app.git', branch: 'main'
            }
        }
        stage('Build Docker Image') {
            steps {
                container('jnlp') {
                    sh 'docker build -t gcr.io/concise-orb-439615-r5/survey-app:latest .'
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                container('jnlp') {
                    sh 'docker push gcr.io/concise-orb-439615-r5/survey-app:latest'
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                container('jnlp') {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
}
