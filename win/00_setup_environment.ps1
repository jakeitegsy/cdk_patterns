#Setup Environment - nodejs installs latest python
$nodeVersion = "v14.14.0"
$nodePackage = "node-$nodeVersion-x64.msi"

$awsCliPackage = "AWSCLIV2.msi"

$packages = @{
    "node.msi"="https://nodejs.org/dist/$nodeVersion/$nodePackage";
    $awsCliPackage="https://awscli.amazonaws.com/$awsCliPackage";
}

$destination = "$Env:UserProfile\Downloads"

npm install -g aws-cdk

cd $destination
forEach ($package in $packages.keys) {
    (New-Object System.Net.WebClient).DownloadFile($packages.$package, "$destination\$package")
    Start-Process $package -Wait
    Remove-Item $destination\$package -Force
}
