pipeline {
    agent any

    environment {
        APP_NAME = "react-weather-app"
        // Dossiers npm pour le compte système Windows
        NPM_CONFIG_CACHE = "C:\\Windows\\system32\\config\\systemprofile\\AppData\\Local\\npm-cache"
        PATH = "C:\\Windows\\system32\\config\\systemprofile\\AppData\\Roaming\\npm;${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'dev', url: 'https://github.com/Hibaaguir/react-weather-app.git'
            }
        }

        stage('Setup') {
            steps {
                bat """
                mkdir C:\\Windows\\system32\\config\\systemprofile\\AppData\\Roaming\\npm 2>nul
                mkdir C:\\Windows\\system32\\config\\systemprofile\\AppData\\Local\\npm-cache 2>nul
                npm install --legacy-peer-deps --cache "%NPM_CONFIG_CACHE%"
                npm install axios --legacy-peer-deps --cache "%NPM_CONFIG_CACHE%"
                npx update-browserslist-db@latest --force --cache "%NPM_CONFIG_CACHE%"
                """
            }
        }

        stage('Build') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Run Docker') {
            steps {
                bat """
                docker build -t react-weather-app:latest .
                docker run -d -p 3000:80 react-weather-app:latest
                """
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

    

