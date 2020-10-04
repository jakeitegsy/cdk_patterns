/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install node
npm install -g aws-cdk
sudo ln -s /folder/installed/aws-cli/aws /usr/local/bin/aws
sudo ln -s /folder/installed/aws-cli/aws_completer /usr/local/bin/aws/aws_completer
curl https://www.python.org/ftp/python/3.8.6/python-3.8.6-macosx10.9.pkg
sudo installer -pkg python-3.8.6-macosx10.9.pkg
python3 -ensure pip
