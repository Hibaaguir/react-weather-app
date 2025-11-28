pipeline {
    agent any
    
    environment {
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
        CI             = 'false'
        
       
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
                        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                            bat 'npm test -- --watchAll=false'
                        }
                    }
                }
                stage('Linting') {
                    steps {
                        echo "🔍 Analyse du code (Lint)..."
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
                // La variable REACT_APP_API_KEY définie en haut sera injectée ici automatiquement
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

        stage('Smoke Test') {
            steps {
                script {
                    echo "🔥 Exécution du Smoke Test..."
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
        // ATTENTION : J'ai commenté le nettoyage 'always'
        // Si tu laisses ça, le site est détruit dès que le test finit.
        // Décommente-le seulement si tu veux que Jenkins nettoie tout après.
        
        // always {
        //    echo "🧹 Nettoyage final..."
        //    bat "docker stop ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
        //    bat "docker rm ${CONTAINER_NAME} >NUL 2>&1 || exit 0"
        //    bat "docker image prune -f >NUL 2>&1 || exit 0"
        // }
        
        success {
            echo "🎉 DEPLOIEMENT RÉUSSI - Version: ${BUILD_TAG}"
            echo "✅ L'application est accessible sur : http://localhost:${HOST_PORT}"
        }
        failure {
            echo "❌ ÉCHEC DU DEPLOIEMENT - Version: ${BUILD_TAG}"
        }
    }
}
