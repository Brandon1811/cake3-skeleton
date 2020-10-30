String cron_string = BRANCH_NAME == "prod" || BRANCH_NAME == "develop" ? "H H(01-05) * * *" : ""
pipeline {
  agent any
  triggers { cron(cron_string) }
  stages {
    stage('Checkout') {
        steps {
            echo 'Checked out BRANCH_NAME'
        }
    }
    stage('Prepare') {
      steps {
        echo 'PREPARING BUILD FOLDERS...'
        sh 'rm -rf build/coverage'
        sh 'rm -rf build/logs'
        sh 'rm -rf build/pdepend'
        sh 'rm -rf build/phpdox'
        sh 'rm -rf build/phpunit'
        sh 'rm -rf build/analyze'
        sh 'rm -rf tmp/phpstan'
        sh 'mkdir -p build/coverage'
        sh 'mkdir -p build/logs'
        sh 'mkdir -p build/pdepend'
        sh 'mkdir -p build/phpdox'
        sh 'mkdir -p build/phpunit'
        sh 'mkdir -p build/analyze'
        sh 'mkdir -p tmp/phpstan'
        sh 'mkdir -p webroot/cache_js'
        sh 'mkdir -p webroot/cache_css'
      }
    }
    stage('Build') {
      steps {
        echo 'BUILDING...'
        sh 'php -v'
        sh './jenkins_config.sh'
        sh './jenkins_db.sh'
        sh 'composer install'
        sh 'bin/cake asset_compress build'
        sh 'bin/cake cache clearAll'
      }
    }
    stage('Check') {
      steps {
        echo 'CHECKING...'
        sh 'vendor/bin/parallel-lint src tests'
        sh 'vendor/bin/phpcs --config-set installed_paths vendor/cakephp/cakephp-codesniffer'
        sh 'vendor/bin/phpcs --report=checkstyle --report-file=build/analyze/checkstyle-phpcs.xml --standard=CakePHP src tests || exit 0'
        sh 'vendor/bin/phpstan analyze -l 7 --no-progress --error-format=checkstyle src tests > build/analyze/checkstyle-phpstan.xml || exit 0'
      }
    }
    stage('Full Test') {
      steps {
        echo 'TESTING on prod or develop...running all tests'
        sh 'vendor/bin/phpunit -c phpunit.xml || exit 0'
      }
    }
    stage('Analyze') {
      steps {
        echo 'ANALYZING...'
        sh 'vendor/bin/phploc src --exclude vendor/ --log-xml build/analyze/phploc.xml'
        sh 'vendor/bin/phpcpd --log-pmd build/analyze/phpcpd.xml src || exit 0'
        dry canRunOnFailed: true, pattern: 'build/analyze/phpcpd.xml'
        sh 'vendor/bin/phpmd src xml phpmd.xml --reportfile build/analyze/pmd.xml --exclude vendor/ || exit 0'
        pmd canRunOnFailed: true, pattern: 'build/analyze/pmd.xml'
        sh 'vendor/bin/pdepend  --jdepend-xml=build/analyze/pdepend.xml --jdepend-chart=build/analyze/dependencies.svg --overview-pyramid=build/analyze/overview-pyramid.svg src || exit 0'
        }
    }
  }
  post {
    always {
      archiveArtifacts artifacts: 'build/**/*.xml, build/analyze/*.svg, logs/*.log', fingerprint: true
      recordIssues(
          enabledForFailure: true, aggregatingResults: true,
          tools: [checkStyle(pattern: 'build/analyze/checkstyle-*', reportEncoding: 'UTF-8')]
      )
      step([
        $class: 'XUnitPublisher',
        thresholds: [[$class: 'FailedThreshold', unstableThreshold: '3']],
        tools: [[$class: 'JUnitType', pattern: 'build/phpunit/junit.xml']]
      ])
      step([
        $class: 'CloverPublisher',
        cloverReportDir: 'build/coverage',
        cloverReportFileName: 'coverage.xml',
        healthyTarget: [methodCoverage: 70, conditionalCoverage: 80, statementCoverage: 80],
        unhealthyTarget: [methodCoverage: 50, conditionalCoverage: 50, statementCoverage: 50],
        failingTarget: [methodCoverage: 0, conditionalCoverage: 0, statementCoverage: 0]
      ])
    }
  }
}
