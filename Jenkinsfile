pipeline {
    agent none

    environment {
        AWS_REGION = "us-east-1"
        ACCOUNT_ID = sh(script: "curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId", returnStdout: true).trim()
        ECR_URI    = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app"
        IMAGE_TAG  = "latest"
    }

    stages {

        stage('Checkout') {
            agent { label 'master' }
            steps {
                checkout scm
            }
        }

        stage('Lint') {
            agent { label 'master' }
            steps {
                sh """
                    pip3 install flake8 --quiet
                    flake8 app.py --ignore=E501
                """
            }
        }

        stage('Unit Tests') {
            agent { label 'master' }
            steps {
                sh """
                    pip3 install pytest --quiet
                    pytest -q
                """
            }
        }

        stage('Build Docker Image') {
            agent { label 'master' }
            steps {
                sh """
                    echo "Logging into ECR..."
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    echo "Building Docker image..."
                    docker build -t ${ECR_URI}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push to ECR') {
            agent { label 'master' }
            steps {
                sh """
                    echo "Pushing Docker image to ECR..."
                    docker push ${ECR_URI}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on App Server') {
            agent { label 'app-agent' }
            steps {
                sh """
                    echo "Logging into ECR from app-agent..."
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    echo "Stopping old container..."
                    docker rm -f myapp || true

                    echo "Pulling latest image..."
                    docker pull ${ECR_URI}:${IMAGE_TAG}

                    echo "Starting new container..."
                    docker run -d --name myapp -p 80:80 ${ECR_URI}:${IMAGE_TAG}

                    echo "Health check..."
                    sleep 3
                    curl -f http://localhost || (echo 'Health check failed' && exit 1)
                """
            }
        }
    }
}
