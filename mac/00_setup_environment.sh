/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
curl "https://nodejs.org/dist/v12.19.0/node-v12.19.0.pkg" -o "node.pkg"
sudo installer -pkg node.pkg -target /
sudo npm install -g aws-cdk
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
curl https://www.python.org/ftp/python/3.9.0/python-3.9.0-macosx10.9.pkg -o "python.pkg"
sudo installer -pkg python.org -target /
python3 -m ensurepip
