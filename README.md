# BaGet for Docker and Kubernetes

## Reference
- https://github.com/loic-sharma/BaGet
- https://loic-sharma.github.io/BaGet/quickstart/docker/
- https://hub.docker.com/r/loicsharma/baget


## Docker deployment to the local workstation

~~~
# start the container
docker run --name baget -p 80:80 -d -e 'NUGET-SERVER-API-KEY=admin' loicsharma/baget:latest

# see the status
docker container ls

# open the url
open http://127.0.0.1

# publish a package
dotnet nuget push -s http://127.0.0.1/v3/index.json -k admin package.1.0.0.nupkg

# destroy the container
docker container stop baget
docker container rm baget
~~~


## Kubernetes deployment to the local workstation (macOS only)

## Prep your local workstation (macOS only)
1. Clone this repo and work in it's root directory
1. Install Docker Desktop for Mac (https://www.docker.com/products/docker-desktop)
1. In Docker Desktop > Preferences > Kubernetes, check 'Enable Kubernetes'
1. Click on the Docker item in the Menu Bar. Mouse to the 'Kubernetes' menu item and ensure that 'docker-for-desktop' is selected.

NOTE: Run the following commands from the root folder of this repo.

### Deploy Baget
~~~
./local-apply.sh
~~~


Persistent data is stored here: `/Users/Shared/Kubernetes/persistent-volumes/default/baget`


### Create a backup of the persistent volume
~~~
./local-backup.sh
~~~

This backs up the /app/packages folder. The backup will be created in the 'backup' folder in this repo. You can take multiple backups.


### Delete the deployment
~~~
./local-delete.sh
~~~


### Restore from backup (pass it the backup folder name)
~~~
./local-restore.sh 2019-10-31_20-05-55
~~~

Restore from one of your backup folder to populate the packages folder.  The backups are stored in the 'backup' folder in this repo.


### Restart the deployment
~~~
./local-restart.sh
~~~

Some changes may require a restart of the containers.  This script will do that for you.


### Scale the deployment
~~~
kubectl scale --replicas=4 deployment/baget
~~~


### Shell into the container
~~~
./local-shell-baget.sh
~~~


### Get the logs from the container
~~~
./local-logs-baget.sh
~~~


### Values to override

apikey: YWRtaW4=  (the ApiKey for uploading packages to BaGet)
~~~
# generate an ApiKey
openssl rand -base64 15

# base64 encode the ApiKey, use the result in the sed
echo -n admin | base64

sed -i '' 's/apikey: .*/apikey: Base64EncodedApiKey/' yaml.tmp

# base64 decode the password, if you need to see what it is
echo YWRtaW4= | base64 --decode
~~~