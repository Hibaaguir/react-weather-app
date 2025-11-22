stage('Run Docker') {
            steps {
                script {
                    // 1. Définir un nom fixe pour le conteneur de test
                    def containerName = "weather-app-test-container"
                    
                    echo "Nettoyage préventif..."
                    // 2. Tenter d'arrêter et supprimer tout conteneur existant avec ce nom
                    bat "docker stop ${containerName} || echo 'Aucun conteneur a arreter'"
                    bat "docker rm ${containerName} || echo 'Aucun conteneur a supprimer'"
                    
                    echo "Démarrage du nouveau conteneur..."
                    // 3. Lancer le conteneur avec le bon mapping de port (Host:3001 -> Container:80)
                    // Notez le changement : 3001:80 (car Nginx utilise le 80, pas le 3000)
                    bat "docker run -d -p 3001:80 --name ${containerName} weather-app:dev-${env.BUILD_NUMBER}"
                    
                    echo "Attente du démarrage..."
                    sleep(time: 10, unit: "SECONDS")
                }
            }
        }