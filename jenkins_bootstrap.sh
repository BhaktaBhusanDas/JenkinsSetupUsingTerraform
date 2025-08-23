#!/bin/bash

# Set error handling
set -e

# Log all output
exec > >(tee /var/log/jenkins-bootstrap.log) 2>&1

echo "Starting Jenkins bootstrap process..."

# Update system
sudo yum update -y

# Install htop command, git
sudo yum install htop -y
sudo yum install git -y

#Creation of swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo mkdir -p /etc/systemd/system/tmp.mount.d
cat <<'EOF' | sudo tee /etc/systemd/system/tmp.mount.d/override.conf
[Mount]
Options=mode=1777,strictatime,noexec,nosuid,nodev,size=8G
EOF
sudo systemctl daemon-reload
sudo systemctl restart tmp.mount

# Install nodejs
sudo yum install -y nodejs

# Install Docker
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

# Install Java 17 (required for Jenkins)
sudo yum install -y java-17-amazon-corretto

# Add Jenkins repository and install
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install -y jenkins

# Create init.groovy.d directory
sudo mkdir -p /var/lib/jenkins/init.groovy.d


# Create JCasC configuration
mkdir -p /var/lib/jenkins/casc_configs

cat > /var/lib/jenkins/casc_configs/jenkins.yaml << 'EOF'
jenkins:
  systemMessage: "Jenkins configured automatically by JCasC"

jobs:
  - script: >
      pipelineJob('hello-node-docker-pipeline') {
        definition {
          cpsScm {
            scm {
              git {
                remote {
                  url('https://github.com/BhaktaBhusanDas/hello-node-docker.git')
                }
                branches('*/*')
              }
            }
            scriptPath('Jenkinsfile')
          }
        }
        triggers {
          githubPush() // This is the GitHub webhook trigger
        }
      }
EOF

# Create systemd override to skip setup wizard and setup jenkins.yaml
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf << EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs/jenkins.yaml"
EOF

# Create skip setup wizard script
sudo tee /var/lib/jenkins/init.groovy.d/01-skip-wizard.groovy << 'EOF'
#!groovy
import jenkins.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
instance.save()
println "Setup wizard skipped successfully"
EOF

# Adding the jenkins user to the docker group.
sudo usermod -aG docker jenkins

# Create plugin installation script
sudo tee /var/lib/jenkins/init.groovy.d/02-install-plugins.groovy << 'PLUGINEOF'
#!groovy
import jenkins.model.*
import hudson.PluginManager

def instance = Jenkins.instance
def pm       = instance.pluginManager
def uc       = instance.updateCenter

println "Fetching metadata from updates.jenkins.io …"
uc.getSite('default').updateDirectlyNow()

def plugins = [
  'cloudbees-folder',
  'antisamy-markup-formatter',
  'build-timeout',
  'credentials-binding',
  'timestamper',
  'ws-cleanup',
  'ant',
  'gradle',
  'workflow-aggregator',
  'github-branch-source',
  'pipeline-github-lib',
  'pipeline-graph-view',
  'git',
  'ssh-slaves',
  'matrix-auth',
  'ldap',
  'email-ext',
  'mailer',
  'docker-workflow',
  'blueocean',
  'dark-theme',
  'nodejs',
  'configuration-as-code',
  'job-dsl'
]

def newlyInstalled = false

plugins.each { name ->
    if (!pm.getPlugin(name)) {
        def p = uc.getPlugin(name)
        if (p) {
            println "Installing plugin: $name"
            def future = p.deploy()
            future.get()  // wait for completion
            newlyInstalled = true
        } else {
            println "Plugin not found at update center: $name"
        }
    } else {
        println "Already present: $name"
    }
}

if (newlyInstalled) {
    println "Plugins installed, saving configuration and restarting Jenkins…"
    instance.save()
    instance.safeRestart()
} else {
    println "All suggested plugins were already installed"
}

// Marker file to confirm execution
new File('/var/lib/jenkins/init.groovy.d/02.install.complete')
    .text = "Suggested plugins installed @ $${new Date()}\n"
println "Done"
PLUGINEOF

# Create admin user script
sudo tee /var/lib/jenkins/init.groovy.d/03-create-admin-user.groovy << 'USEREOF'
#!groovy
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "Creating admin user..."

// Create security realm
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${admin_username}", "${admin_password}")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println "Admin user '${admin_username}' created successfully"
USEREOF

# Create security configuration script
sudo tee /var/lib/jenkins/init.groovy.d/04-configure-security.groovy << 'SECEOF'
#!groovy
import jenkins.model.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Enable CSRF protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Configure agent-to-master security
def rule = new AdminWhitelistRule()
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// Save configuration
instance.save()
println "Security configuration completed"
SECEOF

# Create enable dark theme script
sudo tee /var/lib/jenkins/init.groovy.d/05-enable-dark-theme.groovy << 'DARKOF'
#!groovy
import jenkins.model.Jenkins
import io.jenkins.plugins.thememanager.ThemeManagerPageDecorator
import io.jenkins.plugins.thememanager.ThemeManagerFactoryDescriptor

// 1 List all available themes and choose by display name
println "Available themes:"
def descriptors = ThemeManagerFactoryDescriptor.all()
descriptors.each { desc ->
    println "  ID=$${desc.getThemeId()}, Name=$${desc.getDisplayName()}"
}

// 2. Select the “Dark” factory (unconditionally dark)
def targetDescriptor = descriptors.find { it.getDisplayName() == "Dark" }
if (targetDescriptor == null) {
    error("No theme found with display name 'Dark'")
}

// 3. Instantiate the ThemeManagerFactory
def darkFactory = targetDescriptor.getInstance()

// 4. Apply globally via ThemeManagerPageDecorator
def decorator = ThemeManagerPageDecorator.get()
decorator.setTheme(darkFactory)
decorator.setDisableUserThemes(true)  // optional: prevent overrides
decorator.save()

// 5. Persist Jenkins config
Jenkins.instance.save()

println("Dark theme ('$${targetDescriptor.getDisplayName()}') has been applied globally.")
DARKOF

# Automating docker hub credential creation
cat << 'GROOVY' > /var/lib/jenkins/init.groovy.d/06-create-dockerhub-creds.groovy
#!/usr/bin/env groovy
import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.*
import hudson.util.Secret

// Docker Hub credential parameters
def dockerHubCredentials = [
    id: 'docker-hub-creds',
    description: 'Docker Hub credentials for pushing images',
    username: "${dockerhub_username}",
    password: "${dockerhub_password}"
]

// Get Jenkins instance and credentials store
Jenkins jenkins = Jenkins.getInstance()
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Check if credential already exists
def existingCredentials = store.getCredentials(domain)
def credentialExists = existingCredentials.any { it.id == dockerHubCredentials.id }

if (credentialExists) {
    println "Credential with ID '$${dockerHubCredentials.id}' already exists. Skipping creation."
} else {
    // Create username/password credential
    def dockerHubCredential = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        dockerHubCredentials.id,
        dockerHubCredentials.description,
        dockerHubCredentials.username,
        dockerHubCredentials.password
    )

    // Add credential to store
    store.addCredentials(domain, dockerHubCredential)

    // Save changes to disk
    jenkins.save()

    println "Successfully created Docker Hub credential with ID: $${dockerHubCredentials.id}"
}
GROOVY

# Set proper ownership and permissions for all init scripts
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/
sudo chmod 644 /var/lib/jenkins/init.groovy.d/*.groovy


# Set proper ownership
chown -R jenkins:jenkins /var/lib/jenkins/casc_configs

# Enable and start Jenkins
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Check Jenkins status
sudo systemctl status jenkins --no-pager

# Create a status check script
sudo tee /usr/local/bin/jenkins-status.sh << 'STATUSEOF'
#!/bin/bash
echo "Jenkins Service Status:"
systemctl status jenkins --no-pager

echo -e "\nJenkins Process:"
ps aux | grep jenkins | grep -v grep

echo -e "\nJenkins Port Check:"
netstat -tlnp | grep :8080

echo -e "\nJenkins Logs (last 20 lines):"
tail -20 /var/log/jenkins/jenkins.log

echo -e "\nBootstrap Log (last 10 lines):"
tail -10 /var/log/jenkins-bootstrap.log
STATUSEOF

sudo chmod +x /usr/local/bin/jenkins-status.sh

echo "Jenkins bootstrap completed successfully!"
echo "Jenkins should be accessible at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Admin credentials: ${admin_username} / ${admin_password}"
echo "Run 'sudo /usr/local/bin/jenkins-status.sh' to check status"
