def portfolioApp
def portfolioVarnish

pipeline {
    agent any
    
    options {
        timestamps()
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
        timeout(time: 15, unit: 'MINUTES')
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
        TEST_DOCKER_COMPOSE = 'test-docker-compose.yml'
        TEST_DOCKER_NETWORK = 'portfolio'
        TEST_DOCKER_CONTAINER = 'varnish:6081'
    }

    stages {
        stage('Build') {
            steps {
                // Build assets
                sh 'mkdir ./vendor || true'
                sh "docker build -t alpha01jenkins/portfolio_gulp:${env.BUILD_NUMBER} -f Docker/gulp/Dockerfile Docker/gulp"
                sh "docker run --rm -v ${env.WORKSPACE}/vendor:/vendor-assets -v ${env.WORKSPACE}/gulpfile.js:/gulpfile.js -v ${env.WORKSPACE}/package.json:/package.json \
                    -e APP_ENV='build' alpha01jenkins/portfolio_gulp:${env.BUILD_NUMBER}"
                
                // Containers
                script {
                    $portfolioApp =  docker.build("alpha01jenkins/portfolio_app:${env.BUILD_NUMBER}", "-f Dockerfile .")
                    $portfolioVarnish = docker.build("alpha01jenkins/portfolio_varnish:${env.BUILD_NUMBER}", "-f Docker/varnish/Dockerfile Docker/varnish")
                }
            }
        }

        stage('Test') {
            steps {
                sh 'docker pull alpha01/alpha01-jenkins'
                sh 'mkdir ./tests || true'
                dir("${env.WORKSPACE}/Jenkins"){
                    sh "sed -i 's/##TAG##/${env.BUILD_NUMBER}/g' test-docker-compose.yml"
                    sh "docker-compose -f $TEST_DOCKER_COMPOSE up -d"

                    retry (10) {
                        sh "docker run --rm -v ${env.WORKSPACE}/tests:/tests --network $TEST_DOCKER_NETWORK -e CONTAINER=$TEST_DOCKER_CONTAINER -e DOMAIN=$DOMAIN -e GOOGLE_GA_STRING=$GOOGLE_GA_STRING \
                            alpha01/alpha01-jenkins phpunit /check_site/tests/CheckSiteTest.php --verbose --log-junit tests/${env.JOB_NAME}-${env.BUILD_NUMBER}.xml"
                        sleep(time: 5, unit: "SECONDS")
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-login') {
                        $portfolioApp.push()
                        $portfolioVarnish.push()
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
            dir("${env.WORKSPACE}/Jenkins"){
                sh "docker-compose -f $TEST_DOCKER_COMPOSE down --rmi all"
            }
        }
        success {
            // CDN Purge
            sh "docker run --rm -e CF_EMAIL=${CF_EMAIL} -e CF_KEY=${CF_KEY} alpha01/alpha01-jenkins /cdn/cloudflare-purge.php --domain ${DOMAIN}"

            // Container cleanup
            sh "docker rmi -f alpha01jenkins/portfolio_gulp:${env.BUILD_NUMBER}"
            sh "docker rmi -f registry.hub.docker.com/alpha01jenkins/portfolio_app:${env.BUILD_NUMBER}"
            sh "docker rmi -f registry.hub.docker.com/alpha01jenkins/portfolio_varnish:${env.BUILD_NUMBER}"
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
