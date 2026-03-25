pipeline {
    agent any

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Deploy') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'feature') {
                        sh '''
                            echo "Feature Branch"
                        '''
                    }
                    else if (env.BRANCH_NAME == 'main') {
                        sh '''
                            echo "Main Branch"
                        '''
                    }
                    else if (env.BRANCH_NAME == 'prefix') {
                        echo 'Prefix branch - only checking'
                    }
                }
            }
        }

    }
}
