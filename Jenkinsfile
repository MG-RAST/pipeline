pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'pwd ; ls ; echo Staring Build'
                sh 'CWL/Inputs/DBs/getpredata.sh CWL/Inputs/DBs/' 
                sh 'docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'docker run -t --rm  -e CREATE_BASELINE=1 -v `pwd`:/pipeline mgrast/pipeline:testing /pipeline/CWL/Tests/testWorkflows.py' 
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}