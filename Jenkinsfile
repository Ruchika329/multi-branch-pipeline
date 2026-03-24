pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        DOCKER_IMAGE_NAME     = 'ruchikaranaa/docker-based-pipeline'
        IMAGE_TAG             = "${BUILD_NUMBER}"

        DEV_SERVER     = 'dev-server.example.com'
        STAGING_SERVER = 'staging-server.example.com'
        PROD_SERVER    = 'prod-server.example.com'

        SSH_CREDENTIALS_ID = 'ssh-deploy-key'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            steps {
                echo '>>> Checkout...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo '>>> Build check...'
                sh 'docker version'
            }
        }

        stage('Test') {
            steps {
                echo '>>> Running tests...'
                sh """
                    docker build -t ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} .
                    docker run --rm ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG}
                    docker rmi 'ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} || true
                """
            }
        }

        // Docker login added
        stage('Docker Build & Push') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_CREDENTIALS_ID) {
                        sh """
                            docker build -t ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} .
                            docker tag ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} ruchikaranaa/docker-based-pipeline:latest
                            docker push ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                            docker push ruchikaranaa/docker-based-pipeline:latest
                        """
                    }
                }
            }
        }

        // : SSH remote deploy
        stage('Deploy: Dev') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DEV_SERVER} '
                        docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} &&
                        docker stop app-dev || true &&
                        docker rm app-dev || true &&
                        docker run -d --name app-dev -p 8081:80 ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                        '
                    """
                }
            }
        }

        stage('Deploy: Staging') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${STAGING_SERVER} '
                        docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} &&
                        docker stop app-staging || true &&
                        docker rm app-staging || true &&
                        docker run -d --name app-staging -p 8082:80 ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                        '
                    """
                }
            }
        }

        // FIX: Manual approval added
        stage('Deploy: Production') {
            steps {
                input message: "Deploy to PRODUCTION?", ok: "Deploy"

                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${PROD_SERVER} '
                        docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} &&
                        docker stop app-prod || true &&
                        docker rm app-prod || true &&
                        docker run -d --name app-prod -p 8083:80 ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Build #${IMAGE_TAG}"
        }
        failure {
            echo "FAILED: Build #${IMAGE_TAG}"
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
