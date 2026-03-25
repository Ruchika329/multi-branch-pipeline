pipeline {
    agent any

    stages {

        stage('Clean') {
            steps {
                deleteDir()
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // GIT_BRANCH = "origin/feature" format mein aata hai
                    def branch = env.GIT_BRANCH?.replaceAll('origin/', '').trim()
                    
                    echo "Branch hai: ${branch}"

                    if (branch == 'feature') {
                        sh '''
                            rm -rf /var/www/feature/*
                            cp -r . /var/www/feature/
                            
                        '''
                        echo 'Feature deployed!'
                    }
                    else if (branch == 'main') {
                        sh '''
                            rm -rf /var/www/main/*
                            cp -r . /var/www/main/
                            
                        '''
                        echo 'Main deployed!'
                    }
                    else if (branch == 'prefix') {
                        echo 'Prefix - only checking'
                    }
                }
            }
        }

    }
}
