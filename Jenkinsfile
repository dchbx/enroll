env.ENGINES_RESULT = 0
env.RSPEC_RESULT = 0
env.CUCUMBER_RESULT = 0

pipeline {
    agent any
    triggers {
      pollSCM("H/5 * * * *")
    }
    environment {
      NEWRELIC_RESULT_KEY = credentials('newrelic-enroll-build-result-key')
      NEWRELIC_RESULT_URL = credentials('newrelic-enroll-build-result-url')
    }
    stages {
      stage("Tests") {
        when {
          branch "jenkins_pipeline"
        }
        failFast true
        parallel {
          stage("Engine RSpec") {
            agent {
              label "master"
            }
            steps {
              checkout([$class: 'GitSCM', branches: [[name: '*/jenkins_pipeline']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/dchbx/enroll/']]])
              script {
                env.ENGINES_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/engines.sh
                """
                echo env.ENGINES_RESULT
                if (env.ENGINES_RESULT != 0) {
                  error "Engine RSpecs Failed"
                }
              }
            }
          }
          stage("RSpec") {
            agent {
              label "slave1"
            }
            steps {
              checkout([$class: 'GitSCM', branches: [[name: '*/jenkins_pipeline']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/dchbx/enroll/']]])
              script {
                env.RSPEC_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/rspec.sh
                """
                echo env.RSPEC_RESULT
                junit allowEmptyResults: true, testResults: 'tmp/rspec_junit_*.xml'
                if (env.RSPEC_RESULT != 0) {
                    error "RSpecs Failed"
                }
              }
            }
          }
          stage("Cucumbers") {
            agent {
              label "slave2"
            }
            steps {
              script {
                checkout([$class: 'GitSCM', branches: [[name: '*/jenkins_pipeline']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/dchbx/enroll/']]])
                env.CUCUMBER_RESULT = sh returnStatus: true, script: """
                source ~/.bashrc || true
                base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
                export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
                export https_proxy=\$http_proxy
                export PATH=/usr/local/bin:\$PATH
                ./jenkins/cucumber.sh
                """
                echo env.CUCUMBER_RESULT
                if (env.CUCUMBER_RESULT != 0) {
                  error "Cucumbers Failed"
                }
              }
            }
          }
        }
        post {
          always {
            sh """
source ~/.bashrc || true
base_domain=`echo \$BUILD_URL | cut -d'/' -f3 | cut -d':' -f1`
export no_proxy=raw.githubusercontent.com,\$base_domain,127.0.0.1
export https_proxy=\$http_proxy
export PATH=/usr/local/bin:\$PATH

engine_failures=${env.ENGINES_RESULT}
rspec_failures=${env.RSPEC_RESULT}
cucumber_results=${env.CUCUMBER_RESULT}

rspec_results=\$((engine_failures+rspec_failures))
rspec_status="passing"

if [ \$rspec_results -eq 0 ]; then
  rspec_status="passing"
else
  rspec_status="failed"
fi

if [ \$cucumber_results -eq 0 ]; then
  cucumber_status="passing"
else
  cucumber_status="failed"
fi           

echo '[{"eventType": "GitHub", "organization": "dchbx", "repo": "enroll", "branch":"master", "build_status": "'\$cucumber_status'", "rspec_failures": "'\$rspec_failures'", "rspec_status": "'\$rspec_status'", "cucumber_failures": "'\$cucumber_results'", "cucumber_status": "'\$cucumber_status'"}]' > status.json
gzip -c status.json | curl --data-binary @- -X POST -H "Content-Type: application/json" -H "X-Insert-Key: ${env.NEWRELIC_RESULT_KEY}" -H "Content-Encoding: gzip"  ${env.NEWRELIC_RESULT_URL}
            """
          }
        }
      }
    }
}