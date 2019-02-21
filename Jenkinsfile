pipeline {
    agent any 
    stages {
        stage('Build') { 
            steps {
                sh 'pwd ; ls ; echo Done' 
                sh 'sudo docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'sudo docker run -t --rm mgrast/pipeline:testing ' 
                sh 'sudo docker run -t --rm -v `pwd`:/pipeline mgrast/pipeline:testing /pipeline/CWL/Tests/testTools.py'
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}