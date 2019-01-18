pipeline {
    agent any 
    stages {
        stage('Build') { 
            steps {
                sh 'sudo docker built -t mgrast/pipeline:testing .' 
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