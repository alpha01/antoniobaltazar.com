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
        CF_EMAIL = credentials('CF_EMAIL')
        CF_KEY   = credentials('CF_KEY')
        DOCKER_CERT_PATH = credentials('docker-hub-login')
        TEST_PORT = "$RANDOM"
        TEST_DOCKER_COMPOSE = 'Jenkins/test-docker-compose.yml'
    }

    stages {
        stage('Build') {
            steps {
                git url: 'git@github.com:alpha01/antoniobaltazar.com.git', branch: 'v3'
                script {
                    def portfolioApp =  docker.build("alpha01jenkins/portfolio_app:${env.BUILD_NUMBER}", "-f Dockerfile .")
                    def portfolioVarnish = docker.build("alpha01jenkins/portfolio_varnish:${env.BUILD_NUMBER}", "-f Docker/varnish/Dockerfile Docker/varnish")
                }
            }
        }

        stage('Test') {
            steps {
                sh 'docker pull alpha01/alpha01-jenkins'
                dir("${env.WORKSPACE}/Jenkins"){
                    sh "export TAG=${env.BUILD_NUMBER} ./jenkins_test_pipeline.sh"
                    sh "docker-compose -f $TEST_DOCKER_COMPOSE up -d"
                    sh "docker run --rm -it -v ${env.WORKSPACE}/tests:/tests -e DOMAIN=$DOMAIN -e GOOGLE_GA_STRING=$GOOGLE_GA_STRING \
                        alpha01/alpha01-jenkins phpunit /check_site/tests/CheckSiteTest.php --verbose --log-junit tests/${env.JOB_NAME}-${env.BUILD_NUMBER}.xml"
                    sh "docker-compose -f $TEST_DOCKER_COMPOSE down"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    docker.withRegistry('https://hub.docker.com/', 'docker-hub-login') {
                        portfolioApp.push()
                        portfolioVarnish.push()
                    //sh "docker push alpha01jenkins/portfolio_app:${env.BUILD_NUMBER}"
                    //sh "docker push alpha01jenkins/portfolio_varnish:${env.BUILD_NUMBER}"
                    }
                }
                //Deploy to DCOS here!
            }
        }


    }

    post {
        always {
            echo 'Job run completed.'
            junit 'tests/*xml'
        }
        success {
            sh "docker run --rm -it -e CF_EMAIL=${CF_EMAIL} -e CF_KEY=${CF_KEY} alpha01/alpha01-jenkins /cdn/cloudflare-purge.php --domain ${DOMAIN}"
            // purge local containers
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
