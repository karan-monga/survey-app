pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'karanmonga/survey-app'  
        DOCKER_HUB_CREDENTIALS = credentials('docker-token')
        GOOGLE_CREDENTIALS = credentials('gcp-service-account')
        CLUSTER_NAME = 'survey-cluster'
        CLUSTER_ZONE = 'us-east1-b'
        PROJECT_ID = 'concise-orb-439615-r5'
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
                        docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy'){
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GC_KEY')]) {
                    sh """
                        gcloud auth activate-service-account --key-file=\$GC_KEY
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${PROJECT_ID}
                        kubectl set image deployment/survey-app-deployment survey-app=${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }
    }
}