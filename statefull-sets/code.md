# Static claims

## Creating a static claim
```
cat <<EOF | kubectl apply -f -​
apiVersion: v1​
kind: PersistentVolumeClaim​
metadata:​
  name: aks-volume-claim​
spec:​
  accessModes:​
  - ReadWriteOnce​
  resources:​
    requests:​
      storage: 10Gi​
EOF​
```

## Using the claim
```
cat <<EOF | kubectl apply -f -​
kind: Pod​
apiVersion: v1​
metadata:​
  name: nginx-pvc​
spec:​
  volumes:​
    - name: nginx-storage​
      persistentVolumeClaim:​
       claimName: aks-volume-claim​
  containers:​
    - name: task-pv-container​
      image: nginx​
      ports:​
        - containerPort: 80​
          name: "http-server"​
      volumeMounts:​
        - mountPath: "/usr/share/nginx/html"​
          name: nginx-storage​
EOF​
```