pipeline {
  agent any

  parameters {
    booleanParam(name: 'RUN_APPLY', defaultValue: false, description: 'Ejecutar apply (requiere confirmación)')
    booleanParam(name: 'RUN_DESTROY', defaultValue: false, description: 'Ejecutar destroy (PELIGRO, requiere confirmación)')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: true, description: 'Auto approve para apply/destroy')
    booleanParam(name: 'CHECKOV_SOFT_FAIL', defaultValue: true, description: 'No fallar el build por findings de Checkov')
  }

  environment {
    ANSIBLE_CONFIG     = "ansible/ansible.cfg"
    ANSIBLE_ROLES_PATH = "ansible/roles"
    AWS_DEFAULT_REGION = "us-east-1"

    // Sonar host (si Jenkins y Sonar están en docker sobre Windows)
    SONAR_HOST_URL     = "http://host.docker.internal:9000"
    SONAR_PROJECT_KEY  = "proyecto-pepa-frontend"
  }

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Sanity: Tools') {
      steps {
        sh '''
          set -e
          whoami
          ansible --version
          terraform -version
          docker version
          node --version
          zip -v | head -n 2
        '''
      }
    }

    stage('Build Lambdas (ZIP)') {
      steps {
        sh '''
          set -euo pipefail
          echo "==> Workspace: $PWD"

          test -d lambdas
          test -f lambdas/package.json

          mkdir -p iac/lambda_artifacts

          echo "==> Installing dependencies (npm ci if lock exists)"
          cd lambdas
          if [ -f package-lock.json ]; then
            npm ci
          else
            npm install
          fi
          cd ..

          echo "==> Packaging Lambdas to iac/lambda_artifacts/"
          HAS_LOCK="false"
          if [ -f lambdas/package-lock.json ]; then HAS_LOCK="true"; fi

          zip_one () {
            NAME="$1"
            OUT="$2"
            rm -f "iac/lambda_artifacts/$OUT"

            if [ "$HAS_LOCK" = "true" ]; then
              (cd lambdas && zip -r "../iac/lambda_artifacts/$OUT" "$NAME" shared node_modules package.json package-lock.json >/dev/null)
            else
              (cd lambdas && zip -r "../iac/lambda_artifacts/$OUT" "$NAME" shared node_modules package.json >/dev/null)
            fi
            echo "   OK -> $OUT"
          }

          zip_one "orders"               "orders.zip"
          zip_one "payments"             "payments.zip"
          zip_one "products"             "products.zip"
          zip_one "notifications_worker" "notifications_worker.zip"
          zip_one "inventory_worker"     "inventory_worker.zip"

          echo "==> Artifacts:"
          ls -lh iac/lambda_artifacts/*.zip
        '''
      }
    }

    stage('Validate') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/validate.yml
          '''
        }
      }
    }

    stage('Checkov') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/checkov.yml \
              -e repo_root="$WORKSPACE" \
              -e checkov_soft_fail=${CHECKOV_SOFT_FAIL}
          '''
        }
      }
    }
    
    stage('SonarQube - Frontend') {
      steps {
        withCredentials([string(credentialsId: 'sonar-frontend-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            set -euo pipefail
            export SONAR_HOST_URL="${SONAR_HOST_URL}"
            export SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY}"
            export SONAR_TOKEN="${SONAR_TOKEN}"

            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/sonar_frontend.yml
          '''
        }
      }
    }

    stage('Plan') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/plan.yml
            grep -n "Plan:" iac/envs/dev/plan.txt | head || true
          '''
        }
      }
    }

    stage('Apply') {
      when { expression { return params.RUN_APPLY } }
      steps {
        input message: "¿Confirmas APPLY en dev?", ok: "Sí, aplicar"
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/apply.yml \
              -e tf_auto_approve=${AUTO_APPROVE}
          '''
        }
      }
    }

    stage('Destroy') {
      when { expression { return params.RUN_DESTROY } }
      steps {
        input message: "ÚLTIMA CONFIRMACIÓN: ¿Destroy en dev?", ok: "Sí, destruir"
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh '''
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/destroy.yml \
              -e tf_auto_approve=${AUTO_APPROVE}
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'cicd/reports/checkov/results.xml', allowEmptyArchive: true
      archiveArtifacts artifacts: 'iac/envs/dev/plan.txt', allowEmptyArchive: true
      archiveArtifacts artifacts: 'iac/lambda_artifacts/*.zip', allowEmptyArchive: true

      archiveArtifacts artifacts: 'frontend/sonar-project.properties', allowEmptyArchive: true
    }
  }
}