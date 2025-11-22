pipeline {
    agent any
    
    environment {
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
        // CORRECTION 1 : On force CI=false pour éviter les échecs sur warnings
        CI             = 'false' 
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "📥 Récupération du code source..."
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev') {
                        env.BUILD_TAG = "dev-${env.BUILD_NUMBER}"
                    } else if (env.TAG_NAME) {
                        env.BUILD_TAG = env.TAG_NAME
                    } else {
                        env.BUILD_TAG = "build-${env.BUILD_NUMBER}"
                    }
                    echo "🏷️ Build Tag: ${env.BUILD_TAG}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "🧹 Nettoyage des anciens modules corrompus..."
                // CORRECTION IMPORTANTE : On supprime node_modules pour forcer une installation propre
                // Cela corrige l'erreur "Cannot find module 'ajv'"
                bat 'if exist node_modules rmdir /s /q node_modules'
                bat 'if exist package-lock.json del package-lock.json'

                echo "📦 Installation propre des dépendances..."
                bat 'npm install --legacy-peer-deps'
            }
        }

        stage('Build React App') {
            steps {
                echo "🏗️ Compilation de l'application React..."
                bat 'npm run build'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Construction de l'image Docker..."
                bat "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
            }
        }

        stage('Run Container (Test Environment)') {
            steps {
                script {
                    echo "🧹 Nettoyage préventif..."
                    // Force le succès si le conteneur n'existe pas
                    bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    
                    echo "🚀 Démarrage du conteneur..."
                    bat "docker run -d -p ${HOST_PORT}:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}"
                    
                    echo "⏳ Attente du démarrage..."
                    sleep(time: 10, unit: 'SECONDS')
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    echo "🧪 Vérification de l'application..."
                    bat "curl -f http://localhost:${HOST_PORT} || exit 1"
                    echo "✅ Smoke Test OK"
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "💾 Archivage..."
                archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                archiveArtifacts artifacts: 'Dockerfile', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "🧹 Nettoyage final..."
            bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
            bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
            bat "docker image prune -f >NUL 2>&1 || exit 0"
        }
        success {
            echo "🎉 BUILD SUCCÈS - Version: ${BUILD_TAG}"
        }
        failure {
            echo "❌ BUILD ÉCHOUÉ - Version: ${BUILD_TAG}"
        }
    }
}
}
