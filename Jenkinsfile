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
    }
  }
}
