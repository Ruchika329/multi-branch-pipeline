pipeline {
    agent {
        docker {
            image 'python:3.11-slim'     // slim version bhi chalta hai, lightweight
            args '-u root'
            reuseNode true
        }
    }

    environment {
        APP_NAME        = 'django-notes-app'
        AWS_REGION      = 'us-east-1'
        ECR_REGISTRY    = 'YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com'   // ← yeh change karna hai
        IMAGE_TAG       = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        DOCKER_IMAGE    = "${ECR_REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
        PYTHONPATH      = "${WORKSPACE}"   // optional
    }

    stages {
        stage('Branch Info') {
            steps {
                echo " Branch: ${env.BRANCH_NAME}"
                echo " Build Number: ${env.BUILD_NUMBER}"
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                echo ' Git se source code pull ho gaya'
            }
        }

        stage('Build') {
            steps {
                echo ' Creating virtual environment & installing dependencies'
                sh '''
                    python -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python manage.py collectstatic --noinput
                '''
            }
        }

        stage('Test') {
            steps {
                echo ' Unit + integration tests run'
                sh '''
                    . venv/bin/activate
                    python manage.py test
                '''
            }
        }

        stage('Docker image build') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'feature/*'
                    branch 'main'
                    branch 'prod'
                }
            }
            steps {
                echo 'Docker image build + ECR push'
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        docker build -t ${DOCKER_IMAGE} .
                        docker push ${DOCKER_IMAGE}
                    """
                }
            }
        }

        // Deploy stages (Dev, Staging, Prod) — same as pehle wale rakh sakti ho
        // ...
    }

    post {
        failure {
            echo ' Koi bhi stage fail hone par → Fail + Alert'
        }
        always {
            echo "Pipeline complete for branch: ${env.BRANCH_NAME}"
        }
    }
}
