import jenkins.model.*

url = System.env.JENKINS_URL
urlConfig = JenkinsLocationConfiguration.get()
urlConfig.setUrl(url)
urlConfig.save()