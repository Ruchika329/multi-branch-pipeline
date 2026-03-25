pipeline {
    agent any

    stages {

        stage('Clean') {
            steps {
                deleteDir()
            }
        }

        stage('Deploy Main') {
            when {
                expression {
                    env.BRANCH_NAME == 'main'
                }
            }
            steps {
                sh 'cp -r . /var/www/main/'
            }
        }

        stage('Deploy Feature') {
            when {
                expression {
                    env.BRANCH_NAME == 'feature'
                }
            }
            steps {
                sh 'cp -r . /var/www/feature/'
            }
        }

        stage('Prefix Check') {
            when {
                expression {
                    env.BRANCH_NAME == 'prefix'
                }
            }
            steps {
                echo "Branch hai: ${env.BRANCH_NAME}"
                echo 'Prefix branch - only checking'
            }
        }

    }
}
