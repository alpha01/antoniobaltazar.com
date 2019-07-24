pipeline {
    agent any
    
    options {
        timestamps()
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
        timeout(time: 3, unit: 'MINUTES')
    }

    triggers {
        pollSCM('H/3 * * * *')
    }

    environment {
        DOMAIN   = 'antoniobaltazar.com'
        GOOGLE_GA_STRING = 'UA-12912270-4'
        ADMIN_EMAIL  = credentials('ADMIN_EMAIL')
        DEPLOY_HOSTS = credentials('DEPLOY_HOSTS')
        SSH_PORT = credentials('SSH_PORT')
        VARNISH  = credentials('VARNISH')
        CF_EMAIL = credentials('CF_EMAIL')
        CF_KEY   = credentials('CF_KEY')
        PATH = "/opt/remi/php72/root/bin:/usr/local/phpunit-8.1.3:/usr/local/src/node-v10.16.0-linux-x64/bin:$PATH"
    }

    stages {
        stage('Build') {
            steps {
                git url: 'git@github.com:alpha01/antoniobaltazar.com.git', branch: 'master'
                sh 'npm install'
                sh 'gulp'
            }
        }

        stage('Deploy') {
            steps {
                sh "rsync -av \
                    -e 'ssh -p ${SSH_PORT}' \
                    --exclude=*git* \
                    --exclude=README.md \
                    --exclude=LICENSE \
                    --exclude=Jenkinsfile \
                    --exclude=tests \
                    --exclude=node_modules \
                    --exclude=gulpfile.js \
                    --exclude=*.json \
                    --delete \
                    ${env.WORKSPACE}/ \
                    deploy@${DEPLOY_HOSTS}:/www/${DOMAIN}/"
            }

        }

        stage('Test') {
            steps {
                sh 'mkdir tests || true'
                sh "phpunit ${env.JENKINS_HOME}/phpunit/tests/CheckSiteTest.php --verbose --log-junit tests/${JOB_NAME}-${BUILD_NUMBER}.xml"	
            }
        }
    }

    post {
        always {
            echo 'Job run completed.'
            junit 'tests/*xml'
        }
        success {
            sh "curl -s -x '' -H 'Host: www.${DOMAIN}' http://${VARNISH}:80/ -X PURGE -A 'Jenkins' --verbose"
            sh "${env.JENKINS_HOME}/cdn/cloudflare-purge.php --domain ${DOMAIN}"
        }
        failure {
            mail to: "$ADMIN_EMAIL",
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "Something is wrong with ${env.BUILD_URL}"
        }
        fixed {
            mail to: "$ADMIN_EMAIL",
            subject: "Fixed Pipeline: ${currentBuild.fullDisplayName}",
            body: "Build ${env.JOB_NAME} has returned to a successful build status.\n${env.BUILD_URL}"
        }
        unstable {
            mail to: "$ADMIN_EMAIL",
            subject: "Unstable Pipeline: ${currentBuild.fullDisplayName}",
            body: "Something is wrong with ${env.BUILD_URL}"
        }
    }
}
