pipeline {
    agent any 
    stages {
        stage('Build') { 
            steps {
                sh 'docker built -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'echo Test Step' 
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo Deploy Step'
            }
        }
    }
}