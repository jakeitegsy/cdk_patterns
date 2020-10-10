/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install node
npm install -g aws-cdk
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
curl https://www.python.org/ftp/python/3.9.0/python-3.9.0-macosx10.9.pkg -o "python.pkg"
sudo installer -pkg python.org
python3 -ensure pip
