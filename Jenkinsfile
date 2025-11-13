pipeline {

    agent any

    environment {
        AWS_REGION = "us-east-1"
        ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
        REPO_NAME  = sh(script: "$ECR_URL", returnStdout: true).trim()
        ECR_URI    = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
        IMAGE_TAG  = "latest"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Code Quality') {
            steps {
                sh """
                    pip3 install flake8
                    flake8 app.py --ignore=E501
                """
            }
        }

        stage('Unit Tests') {
            steps {
                sh """
                    pip3 install -r requirements.txt
                    pytest -q
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "Building Docker image from repo..."
                    docker build -t ${ECR_URI}:${IMAGE_TAG} ./app/.
                """
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    echo "Logging into ECR..."
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    echo "Pushing image to ECR..."
                    docker push ${ECR_URI}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on App EC2') {
            agent { label 'app-agent' }

            steps {
                sh """
                    echo "Login to ECR (app-agent)..."
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    echo "Pulling latest image..."
                    docker pull ${ECR_URI}:${IMAGE_TAG}

                    echo "Restart container..."
                    docker rm -f app_container || true

                    docker run -d --name app_container -p 80:80 ${ECR_URI}:${IMAGE_TAG}

                    echo "Deployment complete."
                """
            }
        }

        stage('Health Check') {
            agent { label 'app-agent' }
            steps {
                sh """
                    sleep 5
                    STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

                    if [ "\$STATUS" != "200" ]; then
                        echo "Health check failed! Status: \$STATUS"
                        exit 1
                    fi

                    echo "App is healthy!"
                """
            }
        }
    }
}
