pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'echo Checking for database volume
                    volume=`docker volume ls | grep pipeline-pre-data`
                    if [[ "$volume" == "" ]] 
                    then
                        echo Can not find docker volume pipeline-pre-data, creating volume
                        docker run -t -v pipeline-pre-data:/DBs -v `pwd`:/pipeline mgrast/pipeline:testing  /pipeline/CWL/Inputs/DBs/getpredata.sh /DBs/
                    else
                        echo Found volume pipeline-pre-data, using it
                    fi    
                    '
                // sh 'CWL/Inputs/DBs/getpredata.sh CWL/Inputs/DBs/' 
                sh 'docker build -t mgrast/pipeline:testing .' 
            }
        }
        stage('Test') { 
            steps {
                sh 'docker run -t --rm  -e CREATE_BASELINE=1 -v `pwd`:/pipeline -v pipeline-pre-data:/pipeline/CWL/Inputs/DBs mgrast/pipeline:testing /pipeline/CWL/Tests/testWorkflows.py' 
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}