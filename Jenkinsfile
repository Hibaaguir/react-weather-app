pipeline {
    agent any
    
    environment {
        // Configuration
        IMAGE_NAME     = 'hibaaguir/react-weather-app'
        // Nom fixe pour permettre le nettoyage automatique
        CONTAINER_NAME = 'weather-app-test-container'
        HOST_PORT      = '3001'
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
                    // Définition d'un tag unique pour l'image Docker
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
                echo "📦 Installation des dépendances..."
                bat 'npm install --legacy-peer-deps'
            }
        }

        stage('Build React App') {
            steps {
                echo "🏗️ Compilation de l'application React..."
                // "set CI=false" est important sous Windows pour ne pas échouer sur les warnings
                bat 'set CI=false && npm run build'
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
                    echo "🧹 Nettoyage préventif des anciens conteneurs..."
                    // On essaie d'arrêter et supprimer le conteneur s'il existe déjà (évite l'erreur de port)
                    bat "docker stop ${CONTAINER_NAME} || echo 'Aucun conteneur a arreter'"
                    bat "docker rm ${CONTAINER_NAME} || echo 'Aucun conteneur a supprimer'"
                    
                    echo "🚀 Démarrage du conteneur de test..."
                    // IMPORTANT : Mapping du port 3001 vers 80 (car Nginx écoute sur le 80)
                    bat "docker run -d -p ${HOST_PORT}:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}:${BUILD_TAG}"
                    
                    echo "⏳ Attente du démarrage de Nginx..."
                    sleep(time: 10, unit: 'SECONDS')
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    echo "🧪 Vérification de la disponibilité..."
                    // Vérifie simplement que le serveur renvoie un code 200 OK
                    bat "curl -f http://localhost:${HOST_PORT} || exit 1"
                    echo "✅ Smoke Test RÉUSSI : L'application répond sur le port ${HOST_PORT}"
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "💾 Archivage des fichiers..."
                // Archive le dossier build généré par React
                archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                archiveArtifacts artifacts: 'Dockerfile', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "🧹 Nettoyage final..."
            // Arrêt propre du conteneur de test
            bat "docker stop ${CONTAINER_NAME} || echo 'Déjà arrêté'"
            bat "docker rm ${CONTAINER_NAME} || echo 'Déjà supprimé'"
            
            // Nettoyage des images "dangling" pour économiser de l'espace disque
            bat "docker image prune -f || echo 'Rien a nettoyer'"
        }
        success {
            echo "🎉 BUILD SUCCÈS - Version: ${BUILD_TAG}"
        }
        failure {
            echo "❌ BUILD ÉCHOUÉ - Version: ${BUILD_TAG}"
        }
    }
}