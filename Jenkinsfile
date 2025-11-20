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
                sh 'npm install'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Run Docker') {
            steps {
                sh 'docker build -t react-weather-app:latest .'
                sh 'docker run -d -p 3000:80 react-weather-app:latest'
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
                if [ "$STATUS" -eq 200 ]; then
                  echo "Smoke Test Passed"
                else
                  echo "Smoke Test Failed"
                  exit 1
                fi
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
                sh 'docker stop $(docker ps -q --filter ancestor=react-weather-app:latest) || true'
                sh 'docker rm $(docker ps -a -q --filter ancestor=react-weather-app:latest) || true'
            }
        }
    }
}
