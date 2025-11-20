pipeline {
    agent any

    environment {
        APP_NAME = "react-weather-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'dev', url: 'https://github.com/Hibaaguir/react-weather-app.git'
            }
        }

        stage('Setup') {
            steps {
                bat 'npm install --legacy-peer-deps'
            }
        }

        stage('Build') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Run Docker') {
            steps {
                bat 'docker build -t react-weather-app:latest .'
                bat 'docker run -d -p 3000:80 react-weather-app:latest'
            }
        }

        stage('Smoke Test') {
            steps {
                // Test HTTP avec PowerShell pour Windows
                bat '''
                powershell -Command "$status = (Invoke-WebRequest -Uri http://localhost:3000 -UseBasicParsing).StatusCode; if ($status -eq 200) { Write-Host 'Smoke Test Passed' } else { Write-Host 'Smoke Test Failed'; exit 1 }"
                '''
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**, logs/**', fingerprint: true
            }
        }

        stage('Cleanup') {
            steps {
                // Arrêter et supprimer les containers Docker sous Windows
                bat '''
                for /f "tokens=*" %%i in ('docker ps -q --filter "ancestor=react-weather-app:latest"') do docker stop %%i
                for /f "tokens=*" %%i in ('docker ps -a -q --filter "ancestor=react-weather-app:latest"') do docker rm %%i
                '''
            }
        }
    }
}

        }
    }
}
