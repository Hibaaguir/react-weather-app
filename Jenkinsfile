pipeline {
    agent any

    environment {
        APP_NAME = "react-weather-app"
    }

    stages {

        stage('Checkout') {
            steps {
                deleteDir()  // Nettoyage workspace
                git branch: 'dev', url: 'https://github.com/Hibaaguir/react-weather-app.git'
            }
        }

        stage('Setup') {
            steps {
                bat 'npm install --legacy-peer-deps'
                bat 'npm install axios --legacy-peer-deps'
                bat 'npx update-browserslist-db@latest --force'
            }
        }

        stage('Build') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Run Docker') {
            steps {
                bat "docker build -t ${APP_NAME}:latest ."
                bat "docker run -d -p 3000:80 ${APP_NAME}:latest"
            }
        }

        stage('Smoke Test') {
            steps {
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
                bat '''
for /f "tokens=*" %%i in ('docker ps -q --filter "ancestor=react-weather-app:latest"') do docker stop %%i
for /f "tokens=*" %%i in ('docker ps -a -q --filter "ancestor=react-weather-app:latest"') do docker rm %%i
                '''
            }
        }
    }
}
