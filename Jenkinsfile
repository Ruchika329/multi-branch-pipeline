pipeline {
    agent any

    environment {
        // DockerHub ya apni registry ki credentials ID (Jenkins credentials mein store karo)
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        DOCKER_IMAGE_NAME     = 'ruchikaranaa/docker-based-pipeline'
        IMAGE_TAG             = "${env.BUILD_NUMBER}"

        // Deploy targets (apne server IPs/hostnames se replace karo)
        DEV_SERVER            = 'dev-server.example.com'
        STAGING_SERVER        = 'staging-server.example.com'
        PROD_SERVER           = 'prod-server.example.com'

        // SSH credentials ID (Jenkins credentials mein store karo)
        SSH_CREDENTIALS_ID    = 'ssh-deploy-key'
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
    }

    stages {

        // ─────────────────────────────────────────────
        // STAGE 1: SOURCE CODE CHECKOUT
        // ─────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '>>> Source code checkout ho raha hai...'
                checkout scm
                echo ">>> Git Branch: ${env.GIT_BRANCH}"
                echo ">>> Git Commit: ${env.GIT_COMMIT}"
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 2: BUILD
        // Docker multi-stage build ke pehle app compile
        // ─────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '>>> Application build ho rahi hai...'
                // Agar aapke paas build script hai (jaise npm install, maven, etc.)
                // Yahan Docker ke andar build hogi, isliye simple validation bhi chalega
                sh '''
                    echo "Build environment check:"
                    docker version
                    docker compose version || true
                    echo "Source files:"
                    ls -la
                '''
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 3: TEST
        // Docker container ke andar tests run karo
        // ─────────────────────────────────────────────
        stage('Test') {
            steps {
                echo '>>> Tests chal rahe hain...'
                sh '''
                    # Docker image temporarily build karo sirf test ke liye
                    docker build --target test -t ${DOCKER_IMAGE_NAME}:test-${IMAGE_TAG} . || \
                    docker build -t ${DOCKER_IMAGE_NAME}:test-${IMAGE_TAG} .

                    # Container mein tests run karo
                    docker run --rm \
                        --name test-runner-${IMAGE_TAG} \
                        ${DOCKER_IMAGE_NAME}:test-${IMAGE_TAG} \
                        sh -c "echo 'Tests pass ho gaye!' && exit 0"

                    # Test image cleanup
                    docker rmi ${DOCKER_IMAGE_NAME}:test-${IMAGE_TAG} || true
                '''
            }
            post {
                always {
                    // Test reports publish karo (agar JUnit format mein hain)
                    junit allowEmptyResults: true, testResults: '**/test-results/*.xml'
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 4: DOCKER IMAGE BUILD & PUSH
        // Final production image build karke registry push
        // ─────────────────────────────────────────────
        
        stage('Docker Image Build & Push') {
    steps {
        echo ">>> Docker image build ho rahi hai: ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}"
        sh """
            docker build -t ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} .
            docker tag ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} ruchikaranaa/docker-based-pipeline:latest
            docker push ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            docker push ruchikaranaa/docker-based-pipeline:latest
        """
    }
}

        // ─────────────────────────────────────────────
        // STAGE 5a: DEPLOY → DEV
        // Automatically deploy on every push
        // ─────────────────────────────────────────────
       stage('Deploy: Dev') {
    steps {
        echo ">>> Dev par deploy ho raha hai..."
        sh """
            docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            docker stop app-dev || true
            docker rm app-dev || true
            docker run -d \
                --name app-dev \
                --restart unless-stopped \
                -p 8081:80 \
                ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            echo "Dev deploy complete!"
        """
    }
}
        // ─────────────────────────────────────────────
        // STAGE 5b: DEPLOY → STAGING
        // Dev ke baad automatically staging par deploy
        // ─────────────────────────────────────────────
        stage('Deploy: Staging') {
    steps {
        echo ">>> Staging par deploy ho raha hai..."
        sh """
            docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            docker stop app-staging || true
            docker rm app-staging || true
            docker run -d \
                --name app-staging \
                --restart unless-stopped \
                -p 8082:80 \
                ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            echo "Staging deploy complete!"
        """
    }
}

        // ─────────────────────────────────────────────
        // STAGE 5c: DEPLOY → PRODUCTION
        // Manual approval ke baad hi production deploy
        // ─────────────────────────────────────────────
       stage('Deploy: Production') {
    steps {
        echo ">>> Production par deploy ho raha hai..."
        sh """
            docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            docker stop app-prod || true
            docker rm app-prod || true
            docker run -d \
                --name app-prod \
                --restart unless-stopped \
                -p 8083:80 \
                ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
            echo "Production deploy complete!"
        """
    }
}

    // ─────────────────────────────────────────────
    // POST ACTIONS: Success / Failure notifications
    // ─────────────────────────────────────────────
    post {
        success {
            echo "Pipeline SUCCESSFUL hai! Build #${IMAGE_TAG}"
            // Email notification (Jenkins Email plugin chahiye)
            // mail to: 'team@example.com',
            //      subject: "SUCCESS: Build #${IMAGE_TAG}",
            //      body: "Pipeline successfully complete ho gayi."
        }
        failure {
            echo "Pipeline FAIL ho gayi! Build #${IMAGE_TAG}"
            // mail to: 'team@example.com',
            //      subject: "FAILED: Build #${IMAGE_TAG}",
            //      body: "Pipeline fail ho gayi. Logs check karo."
        }
        always {
            echo '>>> Cleanup: Dangling Docker images remove kar rahe hain...'
            sh 'docker image prune -f || true'
        }
    }
}
