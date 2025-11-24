pipeline {
    agent any
    
    environment {
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
        CI             = 'false' 
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "📥 Récupération du code source..."
                checkout scm
            }
        }

        stage('Setup Versioning') {
            steps {
                script {
                    if (env.TAG_NAME) {
                        env.BUILD_TAG = env.TAG_NAME
                        echo "🏷️ VERSION OFFICIELLE DÉTECTÉE : ${env.BUILD_TAG}"
                    } else if (env.BRANCH_NAME == 'dev') {
                        env.BUILD_TAG = "dev-${env.BUILD_NUMBER}"
                    } else {
                        env.BUILD_TAG = "build-${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "🧹 Nettoyage..."
                bat 'if exist node_modules rmdir /s /q node_modules'
                bat 'if exist package-lock.json del package-lock.json'

                echo "📦 Installation des dépendances..."
                bat 'npm install --legacy-peer-deps'
                bat 'npm install ajv@8.12.0 --legacy-peer-deps'
            }
        }

        stage('Quality Checks (Parallel)') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "🧪 Lancement des tests unitaires..."
                        bat 'npm test -- --watchAll=false --passWithNoTests'
                    }
                }
                stage('Linting') {
                    steps {
                        echo "🔍 Analyse du code (Lint)..."
                        bat 'npm run lint --if-present'
                    }
                }
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
                echo "🐳 Construction de l'image Docker (${env.BUILD_TAG})..."
                bat "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
            }
        }

        stage('Run Container (Test Environment)') {
            steps {
                script {
                    echo "🧹 Nettoyage préventif..."
                    bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    
                    echo "🚀 Démarrage du conteneur..."
                    bat "docker run -d -p ${HOST_PORT}:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}"
                    
                    echo "⏳ Attente du démarrage (20s)..."
                    sleep(time: 20, unit: 'SECONDS')
                }
            }
        }

        // --- CORRECTION MAJEURE ICI ---
        stage('Smoke Test') {
            steps {
                script {
                    echo "🔥 Exécution du Smoke Test..."
                    echo "Vérification statut conteneur..."
                    bat "docker ps -a --filter name=${CONTAINER_NAME}"

                    // Changement: utilisation de 127.0.0.1 au lieu de localhost
                    def result = bat(script: "curl -f http://127.0.0.1:${HOST_PORT}", returnStatus: true)
                    
                    if (result == 0) {
                        echo "✅ SMOKE TEST PASSED"
                        currentBuild.result = 'SUCCESS'
                    } else {
                        echo "❌ SMOKE TEST FAILED"
                        echo "📜 --- LOGS DU CONTENEUR (DEBUG) ---"
                        bat "docker logs ${CONTAINER_NAME}"
                        echo "📜 --------------------------------"
                        error("L'application n'est pas accessible sur le port ${HOST_PORT}.")
                    }
                }
            }
        }
        // ------------------------------

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                archiveArtifacts artifacts: 'Dockerfile', fingerprint: true
            }
        }
    }

    post {
        failure {
            echo "❌ ÉCHEC DU DEPLOIEMENT : Suppression du conteneur..."
            bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
            bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
        }

        success {
            echo "🎉 DEPLOIEMENT RÉUSSI - Version: ${BUILD_TAG}"
            echo "✅ L'application tourne sur : http://localhost:${HOST_PORT}"
        }

        always {
            bat "docker image prune -f >NUL 2>&1 || exit 0"
        }
    }
}
