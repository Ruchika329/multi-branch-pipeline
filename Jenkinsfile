pipeline {
  agent any
  stages {
    stage('Clean') {
      steps { deleteDir() }  
    }
    stage('Clone') {
      steps { checkout scm }
    }
    stage('Deploy Main') {
      when { branch 'main' }
      steps {
        sh 'cp -r . /var/www/main/'  
      }
    }
    stage('Deploy Feature') {
      when { branch 'feature' }
      steps {
        sh 'cp -r . /var/www/feature/'  
      }
    }
    stage('Prefix Check') {
      when { branch 'prefix' }
      steps {
        echo 'Prefix branch - only checking, not deploying'
      }
    }
  }
}
