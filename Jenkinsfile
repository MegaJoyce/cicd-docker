pipeline {

    agent any
/*
	tools {
        maven "maven3"
    }
*/
    environment {
        // NEXUS_VERSION = "nexus3"
        // NEXUS_PROTOCOL = "http"
        // NEXUS_URL = "172.31.40.209:8081"
        // NEXUS_REPOSITORY = "vprofile-release"
        // NEXUS_REPO_ID    = "vprofile-release"
        // NEXUS_CREDENTIAL_ID = "nexuslogin"
        ARTVERSION = "${env.BUILD_ID}"
        registry = "megajoyce/joyceprofile"
        registryCredential = "dockerhub"
    }

    stages{

        // stage('Fetch Code') {
        //     steps {
        //         git branch: 'paac', url: 'https://github.com/devopshydclub/vprofile-project.git'
        //     }
        // }

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
                // Install or configure SonarQube scanner if not done globally
                script {
                    // Assuming the Sonar scanner is already installed in Jenkins tools
                    scannerHome = tool 'mysonarscanner4'
                }

                withSonarQubeEnv('sonar-pro') {
                    sh '''
                ${scannerHome}/bin/sonar-scanner \
                   -Dsonar.host.url=https://sonarcloud.io \
                   -Dsonar.login=${SONAR_TOKEN} \
                   -Dsonar.organization=joyceprofile-qb \
                   -Dsonar.projectKey=joyceprofile-qb_jprofile \
                   -Dsonar.sources=src/ \
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

        stage(Upload image""){
            steps {
                script {
                    docker.withRegistry('', registryCredential){
                        dockerImage.push("v$BUILD_NUMBER")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage(“Remove Unused docker iamge){
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

        // stage("Publish to Nexus Repository Manager") {
        //     steps {
        //         script {
        //             pom = readMavenPom file: "pom.xml";
        //             filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
        //             echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
        //             artifactPath = filesByGlob[0].path;
        //             artifactExists = fileExists artifactPath;
        //             if(artifactExists) {
        //                 echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version} ARTVERSION";
        //                 nexusArtifactUploader(
        //                         nexusVersion: NEXUS_VERSION,
        //                         protocol: NEXUS_PROTOCOL,
        //                         nexusUrl: NEXUS_URL,
        //                         groupId: pom.groupId,
        //                         version: ARTVERSION,
        //                         repository: NEXUS_REPOSITORY,
        //                         credentialsId: NEXUS_CREDENTIAL_ID,
        //                         artifacts: [
        //                                 [artifactId: pom.artifactId,
        //                                  classifier: '',
        //                                  file: artifactPath,
        //                                  type: pom.packaging],
        //                                 [artifactId: pom.artifactId,
        //                                  classifier: '',
        //                                  file: "pom.xml",
        //                                  type: "pom"]
        //                         ]
        //                 );
        //             }
        //             else {
        //                 error "*** File: ${artifactPath}, could not be found";
        //             }
        //         }
        //     }
        // }


    }


}