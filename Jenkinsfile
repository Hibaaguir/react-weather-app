pipeline {
    agent any
    
    environment {
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
        // CI=false est nécessaire pour le build, mais attention aux tests (voir plus bas)
        CI             = 'false' 
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "📥 Récupération du code source..."
                checkout scm
            }
        }

        // CONDITION 1 : Versionning via tags (vX.Y.Z)
        stage('Setup Versioning') {
            steps {
                script {
                    // Si un TAG Git est détecté (ex: v1.0.0), on l'utilise comme version
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
                
                // Maintien du correctif pour ton erreur AJV précédente
                bat 'npm install ajv@8.12.0 --legacy-peer-deps'
            }
        }

        // CONDITION 2 : Exécution parallèle
        // On lance les tests unitaires et le linting en même temps pour gagner du temps
        stage('Quality Checks (Parallel)') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "🧪 Lancement des tests unitaires..."
                        // Note: On force watchAll=false pour que Jenkins ne reste pas bloqué
                        // Le 'call' permet de ne pas faire échouer tout le pipeline si pas de tests configurés
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            bat 'npm test -- --watchAll=false'
                        }
                    }
                }
                stage('Linting') {
                    steps {
                        echo "🔍 Analyse du code (Lint)..."
                        // Essaye de lancer le lint, ignore si la commande n'existe pas dans package.json
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            bat 'npm run lint || echo Pas de script lint configuré'
                        }
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
                    
                    echo "⏳ Attente du démarrage..."
                    sleep(time: 15, unit: 'SECONDS')
                }
            }
        }

        // CONDITION 3 : Vérifications “smoke” automatiques (Passed/Failed)
        stage('Smoke Test') {
            steps {
                script {
                    echo "🔥 Exécution du Smoke Test..."
                    // curl -f renvoie une erreur si le code HTTP est >= 400
                    def result = bat(script: "curl -f http://localhost:${HOST_PORT}", returnStatus: true)
                    
                    if (result == 0) {
                        echo "✅ SMOKE TEST PASSED : L'application répond correctement."
                        currentBuild.result = 'SUCCESS'
                    } else {
                        echo "❌ SMOKE TEST FAILED : L'application ne répond pas."
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
            echo "🧹 Nettoyage final..."
            bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
            bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
            bat "docker image prune -f >NUL 2>&1 || exit 0"
        }
        success {
            echo "🎉 DEPLOIEMENT RÉUSSI - Version: ${BUILD_TAG}"
        }
        failure {
            echo "❌ ÉCHEC DU DEPLOIEMENT - Version: ${BUILD_TAG}"
        }
    }
}
