pipeline {
    agent { label 'master' }  

    environment {
        AWS_REGION = "us-east-1"
        IMAGE_TAG  = "latest"
        PATH       = "${env.PATH}:/var/lib/jenkins/.local/bin"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare Environment Variables') {
            steps {
                script {
                    sh '''
                        echo "=== Debug Info ==="
                        echo "PATH: $PATH"
                        which aws || echo "aws not found in PATH"
                        aws --version || echo "aws command failed"
                        whoami
                        echo "=================="
                    '''

                    def acc = sh(
                        script: 'aws sts get-caller-identity --query Account --output text',
                        returnStdout: true
                    ).trim()

                    env.ACCOUNT_ID = acc
                    env.ECR_URI    = "${acc}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-app"

                    echo "ACCOUNT_ID = ${env.ACCOUNT_ID}"
                    echo "ECR_URI = ${env.ECR_URI}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh """
                    pip install flake8 --quiet
                    cd app
                    flake8 app.py --ignore=E501
                """
            }
        }

        stage('Unit Tests') {
            steps {
                sh """
                    pip install pytest --quiet
                    cd app
                    pytest -q
                """
            }
        }

        stage('Build Docker Image and push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    docker build -t ${ECR_URI}:${IMAGE_TAG} ./app
                    docker push ${ECR_URI}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy on App Server') {
            agent { label 'app' }  
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_URI}

                    docker rm -f myapp || true

                    docker pull ${ECR_URI}:${IMAGE_TAG}

                    docker run -d --name myapp -p 80:5000 ${ECR_URI}:${IMAGE_TAG}

                    sleep 3
                    curl -f http://localhost || (echo 'Health check failed' && exit 1)
                """
            }
        }
    }
