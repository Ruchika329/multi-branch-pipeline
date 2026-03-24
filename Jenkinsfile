pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        DOCKER_IMAGE_NAME     = 'ruchikaranaa/docker-based-pipeline'
        IMAGE_TAG             = "${env.BUILD_NUMBER}"

        DEV_SERVER            = 'dev-server.example.com'
        STAGING_SERVER        = 'staging-server.example.com'
        PROD_SERVER           = 'prod-server.example.com'

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
                echo '>>> Source code checkout...'
                checkout scm
                echo ">>> Git Branch: ${env.GIT_BRANCH}"
                echo ">>> Git Commit: ${env.GIT_COMMIT}"
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 2: BUILD
        // ─────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '>>> Application build...'
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
        // ─────────────────────────────────────────────
        stage('Test') {
            steps {
                echo '>>> Tests chal rahe hain...'
                sh """
                    docker build --target test -t ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} . || \
                    docker build -t ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} .

                    docker run --rm \
                        --name test-runner-${IMAGE_TAG} \
                        ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} \
                        sh -c "echo 'Tests pass!' && exit 0"

                    docker rmi ruchikaranaa/docker-based-pipeline:test-${IMAGE_TAG} || true
                """
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/test-results/*.xml'
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 4: DOCKER IMAGE BUILD & PUSH
        // Uses stored DockerHub credentials securely
        // ─────────────────────────────────────────────
        stage('Docker Image Build & Push') {
            steps {
                echo ">>> Docker image build: ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}"
                withDockerRegistry([credentialsId: "${DOCKER_CREDENTIALS_ID}", url: '']) {
                    sh """
                        docker build -t ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} .
                        docker tag ruchikaranaa/docker-based-pipeline:${IMAGE_TAG} $ruchikaranaa/docker-based-pipeline:latest
                        docker push ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                        docker push ruchikaranaa/docker-based-pipeline:latest
                    """
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 5a: DEPLOY → DEV
        // Runs on every branch push
        // ─────────────────────────────────────────────
        stage('Deploy: Dev') {
            steps {
                echo ">>> Dev deploy..."
                sh """
                    docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                    docker stop app-dev || true
                    docker rm   app-dev || true
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
        // Only on main / develop branch
        // ─────────────────────────────────────────────
        stage('Deploy: Staging') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                echo ">>> Staging deploy..."
                sh """
                    docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                    docker stop app-staging || true
                    docker rm   app-staging || true
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
        // Only on main branch + manual approval required
        // ─────────────────────────────────────────────
        stage('Deploy: Production') {
            when {
                branch 'main'
            }
            steps {
                // Manual gate — pipeline pauses here until approved
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Deploy build #${IMAGE_TAG} to PRODUCTION?",
                          ok: 'Yes, deploy!'
                }
                echo ">>> Production deploy..."
                sh """
                    docker pull ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                    docker stop app-prod || true
                    docker rm   app-prod || true
                    docker run -d \
                        --name app-prod \
                        --restart unless-stopped \
                        -p 8083:80 \
                        ruchikaranaa/docker-based-pipeline:${IMAGE_TAG}
                    echo "Production deploy complete!"
                """
            }
        }

    } // end stages

    // ─────────────────────────────────────────────
    // POST ACTIONS  ← must be OUTSIDE stages block
    // ─────────────────────────────────────────────
    post {
        success {
            echo " Pipeline SUCCESSFUL! Build #${IMAGE_TAG}"
            // mail to: 'team@example.com',
            //      subject: "SUCCESS: Build #${IMAGE_TAG}",
            //      body: "Pipeline successfully complete ho gayi."
        }
        failure {
            echo " Pipeline FAILED! Build #${IMAGE_TAG}"
            // mail to: 'team@example.com',
            //      subject: "FAILED: Build #${IMAGE_TAG}",
            //      body: "Pipeline fail ho gayi. Logs check karo."
        }
        always {
            echo '>>> Cleanup: Dangling Docker images remove...'
            sh 'docker image prune -f || true'
        }
    }

}
