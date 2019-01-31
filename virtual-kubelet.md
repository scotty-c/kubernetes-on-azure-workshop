cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vk-webapp
spec:
  containers:
  - image: scottyc/webapp
    imagePullPolicy: Always
    name: vk-webapp
    resources:
      requests:
        memory: 1G
        cpu: 1
    ports:
    - containerPort: 3000
      name: http
      protocol: TCP
  dnsPolicy: ClusterFirst
  nodeSelector:
    kubernetes.io/role: agent
    beta.kubernetes.io/os: linux
    type: virtual-kubelet
  tolerations:
  - key: virtual-kubelet.io/provider
    operator: Exists
  - key: azure.com/aci
    effect: NoSchedule
EOF

kubectl get pods -o wide
