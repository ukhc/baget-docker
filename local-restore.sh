# Copyright (c) 2019, UK HealthCare (https://ukhealthcare.uky.edu) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################
# validate positional parameters

if [ "$1" == "" ]
then
	echo "USEAGE: ./local-restore.sh [BACKUP_FOLDER_NAME]"
	echo "e.g. ./local-restore.sh local_2019-10-31_20-05-55"
	exit 1
fi

BACKUP_FOLDER="$1"
if [ -d "./backup/$BACKUP_FOLDER" ] 
then
    # ./backup/$BACKUP_FOLDER exists
    echo "Restoring from $BACKUP_FOLDER..."
else
    echo "ERROR: Directory ./backup/$BACKUP_FOLDER does not exist"
	exit 1
fi

##########################

echo
echo "*** WARNING: This script will restore the the data in the persistent volumes ***"
echo "*** WARNING: You will lose any changes you have made in the current deployment ***"
echo
read -n 1 -s -r -p "Press any key to continue or CTRL-C to exit..."

echo

##########################

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

POD=$(kubectl get pod -l app=baget -o jsonpath="{.items[0].metadata.name}")

echo "restore packages..."
kubectl exec $POD -- bash -c "rm -rf /app/packages/*"
kubectl cp ./backup/$BACKUP_FOLDER/packages $POD:/app

##########################

echo "restore database..."
POD=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'drop database if exists baget'
kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'create database baget'
kubectl exec -i $POD -- /usr/bin/mysql -u root -padmin baget < ./backup/$BACKUP_FOLDER/database/baget-dump.sql
# validate
# kubectl exec -it $POD -- /usr/bin/mysql -u root -padmin -e 'use mediawiki;show tables;'

##########################

echo "restart the baget deployment..."
kubectl scale --replicas=0 deployment baget
echo "wait a moment..."
sleep 5
kubectl scale --replicas=1 deployment baget

##########################

# wait for baget
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=baget -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for baget pod. Exit script!"
			exit 1
		else
			echo "waiting...baget pod is not ready...($isPodReadyCount)"
			sleep 2
		fi
	fi
done

##########################

echo "opening the browser..."
open http://127.0.0.1

##########################

echo
echo "...done"