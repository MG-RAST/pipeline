pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'pwd ; ls ; echo Done' 
                sh 'docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'sudo docker run -t --rm mgrast/pipeline:testing ' 
            
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}