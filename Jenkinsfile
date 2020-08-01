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
        APP_ENV = 'build'
        TEST_DOCKER_COMPOSE = 'test-docker-compose.yml'
        TEST_DOCKER_NETWORK = 'portfolio'
        TEST_DOCKER_CONTAINER = 'varnish:6081'
    }

    stages {
        stage('Build') {
            steps {
                // Build assets
                sh "docker build -t alpha01jenkins/portfolio_gulp:${env.BUILD_NUMBER} -f Docker/gulp/Dockerfile Docker/gulp"
                sh "docker run --rm -v ${env.WORKSPACE}/vendor:/vendor-assets -v ${env.WORKSPACE}/gulpfile.js:/gulpfile.js -v ${env.WORKSPACE}/package.json:/package.json \
                    -e APP_ENV=$APP_ENV alpha01jenkins/portfolio_gulp:${env.BUILD_NUMBER}"
                
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
                dir("${env.WORKSPACE}/tests"){
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

        stage('Publish') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-login') {
                        $portfolioApp.push()
                        $portfolioVarnish.push()
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                // Deploy to Mesos
                script {
                    ansibleTower(
                        towerServer: 'AWX',
                        jobTemplate: '11',
                        importTowerLogs: true,
                        removeColor: false,
                        verbose: true,
                        extraVars: """---
                        deploy_mesos_app_server: https://ui-dcos.rubyninja.org
                        deploy_mesos_app: pod
                        deploy_mesos_template: portfolio-pod.json.j2
                        deploy_mesos_app_id: /web/portfolio/portfolio-pod
                        deploy_mesos_app_container:
                          - registry.hub.docker.com/alpha01jenkins/portfolio_app
                          - registry.hub.docker.com/alpha01jenkins/portfolio_varnish
                        deploy_mesos_app_container_tag: ${env.BUILD_NUMBER}
                        deploy_mesos_app_state: present
                        """
                    )
                }
            }
        }
    }

    post {
        always {
            echo 'Job run completed.'
            junit 'tests/*xml'
            dir("${env.WORKSPACE}/tests"){
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
