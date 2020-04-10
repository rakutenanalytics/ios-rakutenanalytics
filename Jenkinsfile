pipeline {
   agent {
       label 'sdk-agents'
   }
   
   options {
        ansiColor("xterm")
    }

   stages {
      stage('Build then test') {
         steps {
            sh 'fastlane ci'
         }
      }
      
      stage('Archive artifacts') {
         steps {
            archiveArtifacts allowEmptyArchive: true, artifacts: 'artifacts/**/*'
        }
      }
   }
   
   post {
        fixed {
            slackSend channel: '#sdk-dev-ci',
                      color: 'good',
                      message: "${currentBuild.fullDisplayName} is back to normal (<${env.BUILD_URL}|Open>)"
        }
        regression {
            slackSend channel: '#sdk-dev-ci',
                      color: 'danger',
                      message: "${currentBuild.fullDisplayName} failed! (<${env.BUILD_URL}|Open>)"
        }
    }
}
