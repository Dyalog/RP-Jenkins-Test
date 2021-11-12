pipeline {
	agent {
		docker {
			image 'rikedyp/dtools:pdf'
			registryCredentialsId '0435817a-5f0f-47e1-9dcc-800d85e5c335'
		}
	}
	stages {
		stage ('GitHub Upload Draft Release') {
			steps {
				withCredentials([string(credentialsId: '250bdc45-ee69-451a-8783-30701df16935', variable: 'GHTOKEN')]) {
					sh './CI/GH-Release.sh'
					stash name: 'major_minor', includes: '___version___'
					stash name: 'repo_name', includes: '___repo___'
				}
			}
		}
		stage ('Publish Documentation') {
			steps {
				withCredentials([string(credentialsId: '250bdc45-ee69-451a-8783-30701df16935', variable: 'GHTOKEN')]) {
					unstash 'major_minor'
					unstash 'repo_name'
					sh './CI/GH-Docs-Deploy.sh'
				}
			}
		}
	}
}
