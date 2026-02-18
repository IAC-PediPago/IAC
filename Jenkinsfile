pipeline {
  agent any

  parameters {
    booleanParam(name: 'RUN_APPLY', defaultValue: false, description: 'Ejecutar apply')
    booleanParam(name: 'AUTO_APPROVE', defaultValue: true, description: 'Auto approve para apply')
    booleanParam(name: 'CHECKOV_SOFT_FAIL', defaultValue: true, description: 'No fallar el build por findings de Checkov')
  }

  environment {
    ANSIBLE_CONFIG     = "ansible/ansible.cfg"
    ANSIBLE_ROLES_PATH = "ansible/roles"
    AWS_DEFAULT_REGION = "us-east-1"
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Sanity: Tools') {
      steps {
        sh '''
          set -e
          whoami
          ansible --version
          terraform -version
          docker version
          node --version || true
          zip -v | head -n 2 || true
        '''
      }
    }

    stage('Build Lambdas (ZIP)') {
      steps {
        sh '''
          set -euo pipefail

          echo "==> Workspace: $WORKSPACE"
          test -d "$WORKSPACE/lambdas" || (echo "ERROR: No existe la carpeta lambdas/ en el repo" && exit 1)

          mkdir -p "$WORKSPACE/iac/lambda_artifacts"

          echo "==> Install deps inside Docker (node:20-alpine)"
          docker run --rm \
            -u "0:0" \
            -v "$WORKSPACE:/work" \
            -w /work/lambdas \
            node:20-alpine \
            sh -lc 'apk add --no-cache zip >/dev/null && if [ -f package-lock.json ]; then npm ci; else npm install; fi'

          echo "==> Packaging Lambdas..."
          HAS_LOCK="false"
          if [ -f "$WORKSPACE/lambdas/package-lock.json" ]; then
            HAS_LOCK="true"
          fi

          targets="orders payments products notifications_worker inventory_worker"
          for d in $targets; do
            zipname="$d.zip"
            echo "  -> $d => iac/lambda_artifacts/$zipname"

            if [ "$HAS_LOCK" = "true" ]; then
              docker run --rm \
                -u "0:0" \
                -v "$WORKSPACE:/work" \
                -w /work/lambdas \
                node:20-alpine \
                sh -lc "apk add --no-cache zip >/dev/null && rm -f /work/iac/lambda_artifacts/$zipname && zip -r /work/iac/lambda_artifacts/$zipname $d shared node_modules package.json package-lock.json >/dev/null"
            else
              docker run --rm \
                -u "0:0" \
                -v "$WORKSPACE:/work" \
                -w /work/lambdas \
                node:20-alpine \
                sh -lc "apk add --no-cache zip >/dev/null && rm -f /work/iac/lambda_artifacts/$zipname && zip -r /work/iac/lambda_artifacts/$zipname $d shared node_modules package.json >/dev/null"
            fi
          done

          echo "==> Artifacts generated:"
          ls -lh "$WORKSPACE/iac/lambda_artifacts"
        '''
      }
    }

    stage('Validate') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-dev',
          usernameVariable: 'AWS_ACCESS_KEY_ID',
          passwordVariable: 'AWS_SECRET_ACCESS_KEY'
        )]) {
          sh """
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/validate.yml \
              -e checkov_soft_fail=${params.CHECKOV_SOFT_FAIL}
          """
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
          sh """
            ansible-playbook -i ansible/inventories/dev/hosts.ini ansible/playbooks/apply.yml \
              -e tf_auto_approve=${params.AUTO_APPROVE}
          """
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tools/checkov/reports/results.xml', allowEmptyArchive: true
      archiveArtifacts artifacts: 'iac/envs/dev/plan.txt', allowEmptyArchive: true

      // Opcional: útil para debug si algo falla con rutas/hashes
      archiveArtifacts artifacts: 'iac/lambda_artifacts/*.zip', allowEmptyArchive: true
    }
  }
}
