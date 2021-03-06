#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Variables

if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then 

    export PROJECT=$(gcloud config get-value project)
    export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
    echo "WORK_DIR set to $WORK_DIR"
    gcloud config set project $PROJECT

    ./connect-hub/cleanup-hub.sh
    ./connect-hub/cleanup-remote-gce.sh&> ${WORK_DIR}/cleanup-remote.log &
    ./gke/cleanup-gke.sh  &> ${WORK_DIR}/cleanup-gke.log &
    #./common/cleanup-tools.sh
    gcloud source repos delete --quiet config-repo
    rm $HOME/.ssh/id_rsa.nomos.*
    wait

    rm -rf $WORK_DIR
    
    # Delete forwarding rule created by Istio ingress gateway on remote cluster
    gcloud compute forwarding-rules delete $(gcloud compute forwarding-rules list --format="value(name)") --region us-central1 --quiet

    # Delete target-pools created by Istio ingress gateway on remote cluster
    gcloud compute target-pools delete $(gcloud compute target-pools list --format="value(name)") --region us-central1 --quiet

    # Delete config-repo fro CSR
    gcloud source repos delete config-repo --quiet

    # Delete kubeconfig
    rm $HOME/.kube/config

    # Delete remaining files and folders
    cd $HOME
    rm -rf config-repo
    rm csm-alpha-onboard-logs
    rm -rf gopath

else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi
