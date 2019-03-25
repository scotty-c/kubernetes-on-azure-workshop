#!/bin/bash

set -ex

kubectl delete -n webapp-namespace deployments.apps webapp-deployment
kubectl delete -n webapp-namespace rolebindings.rbac.authorization.k8s.io webapp-role-binding
kubectl delete -n webapp-namespace roles.rbac.authorization.k8s.io webapp-role 
kubectl delete -n webapp-namespace serviceaccounts webapp-service-account 
