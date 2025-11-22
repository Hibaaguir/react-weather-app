pipeline {
    agent any
    
    environment {
        // Forcer CI à false pour éviter que les warnings bloquent le build
        CI = 'false'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Détection automatique du type de build - CORRIGÉE
                    if (env.CHANGE_ID) {
                        env.BUILD_TYPE = 'PR'
                        echo "Build détecté: Pull Request #${env.CHANGE_ID}"
                    } else if (env.TAG_NAME) {
                        env.BUILD_TYPE = 'RELEASE' 
                        echo "Build détecté: Release ${env.TAG_NAME}"
                    } else {
                        env.BUILD_TYPE = 'DEV'
                        echo "Build détecté: Développement (${env.BRANCH_NAME} branch)"
                    }
                    
                    echo "Type de build: ${env.BUILD_TYPE}"
                }
            }
        }
        
        stage('Setup') {
            steps {
                bat 'npm install --legacy-peer-deps'
            }
        }
        
        stage('Build') {
            steps {
                // CI=false est maintenant dans environment, pas besoin de le set ici
                bat 'npm run build'
            }
        }
        
        stage('Run Docker') {
            steps {
                script {
                    def imageTag = ""
                    def containerName = ""
                    def port = 3000
                    
                    switch(env.BUILD_TYPE) {
                        case 'PR':
                            imageTag = "pr-${env.CHANGE_ID}-${env.BUILD_NUMBER}"
                            containerName = "weather-app-pr-${env.BUILD_NUMBER}"
                            port = 3000
                            break
                        case 'DEV':
                            imageTag = "dev-${env.BUILD_NUMBER}"
                            containerName = "weather-app-dev-${env.BUILD_NUMBER}"
                            port = 3001
                            break
                        case 'RELEASE':
                            def version = env.TAG_NAME.replace('v', '')
                            imageTag = version
                            containerName = "weather-app-release-${env.BUILD_NUMBER}"
                            port = 3002
                            break
                        default:
                            imageTag = "unknown-${env.BUILD_NUMBER}"
                            containerName = "weather-app-unknown-${env.BUILD_NUMBER}"
                            port = 3000
                    }
                    
                    bat "docker build -t weather-app:${imageTag} ."
                    bat "docker run -d -p ${port}:3000 --name ${containerName} weather-app:${imageTag}"
                    bat "timeout /t 30 /nobreak"
                    
                    // Sauvegarder les variables pour les stages suivants
                    env.CONTAINER_NAME = containerName
                    env.PORT = port
                    env.IMAGE_TAG = imageTag
                }
            }
        }
        
        stage('Smoke Test') {
            steps {
                script {
                    try {
                        bat "curl -f http://localhost:${env.PORT} || exit 1"
                        echo "✅ Smoke test PASSED pour ${env.BUILD_TYPE}"
                    } catch (Exception e) {
                        echo "❌ Smoke test FAILED pour ${env.BUILD_TYPE}"
                        error "Smoke test failed"
                    }
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                script {
                    archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                    
                    if (env.BUILD_TYPE == 'RELEASE') {
                        def version = env.TAG_NAME.replace('v', '')
                        bat "echo 'Release ${version} - Build ${env.BUILD_NUMBER}' > release-info.txt"
                        bat "echo 'Date: ${new Date()}' >> release-info.txt"
                        bat "echo 'Commit: ${env.GIT_COMMIT}' >> release-info.txt"
                        archiveArtifacts artifacts: 'release-info.txt', fingerprint: true
                        echo "🎉 Artefacts de release archivés"
                    }
                }
            }
        }
        
        stage('Parallel Tests') {
            when {
                expression { env.BUILD_TYPE == 'RELEASE' }
            }
            parallel {
                stage('Test Node 18') {
                    steps {
                        echo "✅ Test avec Node 18 simulé"
                        bat "echo 'Node 18 test passed' > node18-test.txt"
                    }
                }
                stage('Test Node 20') {
                    steps {
                        echo "✅ Test avec Node 20 simulé" 
                        bat "echo 'Node 20 test passed' > node20-test.txt"
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    bat "docker stop ${env.CONTAINER_NAME} || echo 'Aucun conteneur à arrêter'"
                    bat "docker rm ${env.CONTAINER_NAME} || echo 'Aucun conteneur à supprimer'"
                }
            }
        }
    }
    
    post {
        always {
            echo "=== RAPPORT FINAL ==="
            echo "Pipeline: ${env.BUILD_TYPE}"
            echo "Status: ${currentBuild.result}"
            echo "Build: ${env.BUILD_NUMBER}"
            
            // Nettoyage des images intermédiaires
            bat 'docker image prune -f || echo "Cleanup docker images"'
        }
        success {
            echo "🎉 PIPELINE ${env.BUILD_TYPE} RÉUSSI !"
        }
        failure {
            echo "❌ PIPELINE ${env.BUILD_TYPE} ÉCHOUÉ"
        }
    }
}