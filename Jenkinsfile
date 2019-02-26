pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'Setup/check-and-load-docker-volume.sh'
                // sh 'CWL/Inputs/DBs/getpredata.sh CWL/Inputs/DBs/' 
                sh 'mkdir -p CWL/Data/Baseline'
                sh 'docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'docker run -t --rm  -e CREATE_BASELINE=1 -v `pwd`:/pipeline -v pipeline-pre-data:/pipeline/CWL/Inputs/DBs mgrast/pipeline:testing /pipeline/CWL/Tests/testWorkflows.py -v' 
            }
        }
    }
}
