pipeline {
    agent { 
        node {label 'bare-metal' }
    } 
    stages {
        stage('Build') { 
            steps {
                sh 'pwd ; ls ; echo Done' 
                sh 'sudo docker build -t mgrast/pipeline:testing -f /media/epemeral/jenkins-slave/workspace/AST_pipeline_wilke_setup-testing/.' 
            }
        }
        stage('Test') { 
            steps {
                sh 'sudo docker run -t --rm mgrast/pipeline:testing ' 
                sh 'sudo docker run -t --rm -v /media/ephemeral/jenkins-slave/workspace/AST_pipeline_wilke_setup-testing:/pipeline mgrast/pipeline:testing /pipeline/CWL/Tests/testTools.py'
            }
        }
        stage('Deploy') { 
            steps {
                sh 'echo No deployment'
            }
        }
    }
}