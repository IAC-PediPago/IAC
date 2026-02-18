pipeline {
  agent any

  parameters {
    booleanParam(name: 'RUN_APPLY', defaultValue: false, description: 'Ejecutar apply')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: true, description: 'Auto approve para apply')
    booleanParam(name: 'CHECKOV_SOFT_FAIL', defaultValue: true, description: 'No fallar el build por findings de Checkov')
  }

  environment {
    ANSIBLE_CONFIG = "ansible/ansible.cfg"
    ANSIBLE_ROLES_PATH = "ansible/roles"
    AWS_DEFAULT_REGION = "us-east-1"
  }

  options {
    timestamps()
    ansiColor('xterm')
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

          # opcional: limpiar para no dejar pesado el workspace
          # rm -rf lambdas/node_modules
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
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/validate.yml \
              -e checkov_soft_fail=${CHECKOV_SOFT_FAIL}
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
  }

  post {
    always {
      archiveArtifacts artifacts: 'tools/checkov/reports/results.xml', allowEmptyArchive: true
      archiveArtifacts artifacts: 'iac/envs/dev/plan.txt', allowEmptyArchive: true
      archiveArtifacts artifacts: 'iac/lambda_artifacts/*.zip', allowEmptyArchive: true
    }
  }
}
