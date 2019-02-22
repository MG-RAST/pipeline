pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'pwd ; ls ; echo Staring Build'
                sh 'CWL/Inputs/DBs/getpredata.sh' 
                sh 'docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'sudo docker run --rm  -v `pwd`:/pipeline mgrast/pipeline:testing /pipeline/CWL/Tests/testTools.py' 
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}