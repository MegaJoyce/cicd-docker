pipeline {

    agent any

    environment {
        registry = "megajoyce/joyceprofile"
        registryCredential = "dockerhub"
        // SonarCloud-specific variables
        SONAR_TOKEN = credentials('sonarcloudCred') // Add your SonarCloud token in Jenkins credentials
        SONAR_ORG = 'joyceprofile-qb'
        SONAR_PROJECT_KEY = 'joyceprofile-qb_jprofile'
        HOST_URL = 'https://sonarcloud.io'
    }

    stages{

        stage('BUILD'){
            steps {
                sh 'mvn clean install -DskipTests'
            }
            post {
                success {
                    echo 'Now Archiving...'
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }

        stage('UNIT TEST'){
            steps {
                sh 'mvn test'
            }
        }

        stage('INTEGRATION TEST'){
            steps {
                sh 'mvn verify -DskipUnitTests'
            }
        }

        stage ('CODE ANALYSIS WITH CHECKSTYLE'){
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
            post {
                success {
                    echo 'Generated Analysis Result'
                }
            }
        }

        stage('CODE ANALYSIS with SONARQUBE') {
            steps {
                withSonarQubeEnv('SonarCloud') { // 'sonar-pro' should be the name of the SonarCloud instance in Jenkins
                    sh '''
                    mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                    -Dsonar.organization=${SONAR_ORG} \
                    -Dsonar.host.url=${HOST_URL} \
                    -Dsonar.login=${SONAR_TOKEN} \
                    -Dsonar.sources=src/main/ \
                    -Dsonar.test=src/test/ \
                    -Dsonar.junit.reportsPath=target/surefire-reports/ \
                    -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                    -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml \
                    -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/
                    '''
                }
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage ("Build App Image"){
            steps {
                script {
                    dockerImage = docker.build registry  + ":v$BUILD_NUMBER"
                }
            }
        }

        stage("Upload image"){
            steps {
                script {
                    docker.withRegistry('', registryCredential){
                        dockerImage.push("v$BUILD_NUMBER")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage("Remove Unused docker image"){
            steps {
                sh "docker rmi $registry:v$BUILD_NUMBER"
            }
        }

        stage("kubernetes deploy"){
            agent {label "kops"}
            steps {
                sh "helm upgrade --install -force vprofile-stack helm/vprofilecharts --set appimage=${registry}:v${BUILD_NUMBER} --namespace prod"
            }
        }
    }


}