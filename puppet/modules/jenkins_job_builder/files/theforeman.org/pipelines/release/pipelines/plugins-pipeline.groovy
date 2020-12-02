pipeline {
    agent none

    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    stages {
        stage('Install Test') {
            agent { label 'el' }

            steps {
                script {
                    runCicoPipelines('plugins', foreman_version, pipelines, params.expected_version)
                }
            }
        }
    }
}
