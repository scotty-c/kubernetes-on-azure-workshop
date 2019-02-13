# Installing helm on Kubernetes

## Installing helm
```
#!/bin/bash​
​
if [[ "$OSTYPE" == "linux-gnu" ]]; then​
    OS="linux"​
    ARCH="linux-amd64"​
elif [[ "$OSTYPE" == "darwin"* ]]; then​
    OS="osx"​
    ARCH="darwin-amd64"​
fi    ​
HELM_VERSION=2.11.0​
curl -sL "https://storage.googleapis.com/kubernetes-helm/helm-v$HELM_VERSION-$ARCH.tar.gz" | tar xz​
chmod +x $ARCH/helm ​
sudo mv linux-amd64/helm /usr/local/bin/​
```

## Installing Tiller
```
cat <<EOF | kubectl apply -f -​
apiVersion: v1​
kind: ServiceAccount​
metadata:​
  name: tiller​
  namespace: kube-system​
---​
apiVersion: rbac.authorization.k8s.io/v1beta1​
kind: ClusterRoleBinding​
metadata:​
  name: tiller​
roleRef:​
  apiGroup: rbac.authorization.k8s.io​
  kind: ClusterRole​
  name: cluster-admin​
subjects:​
  - kind: ServiceAccount​
    name: tiller​
    namespace: kube-system​
EOF
``

`helm init --service-account tiller`





