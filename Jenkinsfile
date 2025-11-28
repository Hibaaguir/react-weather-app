pipeline {
    agent any
    
    environment {
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
        CI             = 'false'
        // AJOUT ESSENTIEL : La clé API pour que l'app fonctionne une fois lancée
        REACT_APP_API_KEY = '35ab6beb19578ca806a2bf1aa82cfead'
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
                // Injection forcée de la clé API pour Windows
                bat "set REACT_APP_API_KEY=${REACT_APP_API_KEY} && npm run build"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Construction de l'image Docker (${env.BUILD_TAG})..."
                bat "docker build -t ${IMAGE_NAME}:${BUILD_TAG} ."
            }
        }

        stage('Run Container') {
            steps {
                script {
                    echo "🧹 Suppression de l'ancien conteneur s'il existe..."
                    // On ne supprime que l'ancien pour laisser la place au nouveau
                    bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
                    
                    echo "🚀 Démarrage du NOUVEAU conteneur..."
                    // Le conteneur démarre en mode détaché (-d) et restera actif après le pipeline
                    bat "docker run -d -p ${HOST_PORT}:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}"
                    
                    echo "⏳ Attente du démarrage (15s)..."
                    sleep(time: 15, unit: 'SECONDS')
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    echo "🔥 Exécution du Smoke Test..."
                    def result = bat(script: "curl -f http://localhost:${HOST_PORT}", returnStatus: true)
                    
                    if (result == 0) {
                        echo "✅ SMOKE TEST PASSED"
                        currentBuild.result = 'SUCCESS'
                    } else {
                        echo "❌ SMOKE TEST FAILED"
                        error("L'application a échoué au smoke test.")
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                archiveArtifacts artifacts: 'Dockerfile', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "🧹 Nettoyage des images intermédiaires (prune)..."
            // On nettoie seulement les images "dangling" (inutiles) pour gagner de la place
            // MAIS ON NE TOUCHE PAS AU CONTENEUR ACTIF
            bat "docker image prune -f >NUL 2>&1 || exit 0"
        }
        success {
            echo "🎉 DÉPLOIEMENT RÉUSSI - Version: ${BUILD_TAG}"
            echo "--------------------------------------------------"
            echo "✅ L'APPLICATION TOURNE ICI : http://localhost:${HOST_PORT}"
            echo "--------------------------------------------------"
        }
        failure {
            echo "❌ ÉCHEC DU DÉPLOIEMENT - Version: ${BUILD_TAG}"
        }
    }
}
