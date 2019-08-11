# Deploying Super Gloo

In this module we deploy [super gloo](https://supergloo.solo.io/). Super gloo is a super powerful tool that allows you to orchestrate service meshes on top of Kubernetes. Super Gloo has two main interfaces to install meshes on Kubernetes, a cli or a web front end. In this module we will install both.

##cli
To install the cli you need to chose one of the following depending on your OS type.

If your using the pre built Docker container you can skip the install as the container already has the binary for you.

For MacOS
```
brew install solo-io/tap/supergloo
```

For Linux/WSL/Cloud shell
```
curl -sL https://run.solo.io/supergloo/install | sh
```

Then we need to add the binary to our path
```
export PATH=$HOME/.supergloo/bin:$PATH
```

We can test that everything is working buy just issuing the command `supergloo` and you will get the following out put.

```
16:23 $ supergloo
supergloo configures resources watched by the Supergloo Controller.
	Find more information at https://solo.io

Usage:
  supergloo [command]

Available Commands:
  apply       apply a rule to a mesh
  completion  generate auto completion for your shell
  create      commands for creating resources used by SuperGloo
  get         get information about supergloo objects
  help        Help about any command
  init        install SuperGloo to a Kubernetes cluster
  install     install a service mesh using Supergloo
  register    commands for registering meshes with SuperGloo
  set         update an existing resource with one or more config options
  uninstall   uninstall a service mesh using Supergloo
  upgrade     upgrade your supergloo cli binary to the latest version

Flags:
  -h, --help      help for supergloo
      --version   version for supergloo

Use "supergloo [command] --help" for more information about a command.
```

Now let's initialise Super Gloo on our cluster. To do that we issue the following command
```
supergloo init
```

You will get an output like the one listed below
```
16:08 $ supergloo init
installing supergloo version 0.3.22
using chart uri https://storage.googleapis.com/supergloo-helm/charts/supergloo-0.3.22.tgz
configmap/sidecar-injection-resources created
serviceaccount/supergloo created
serviceaccount/discovery created
serviceaccount/mesh-discovery created
clusterrole.rbac.authorization.k8s.io/discovery created
clusterrole.rbac.authorization.k8s.io/mesh-discovery created
clusterrolebinding.rbac.authorization.k8s.io/supergloo-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/discovery-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/mesh-discovery-role-binding created
deployment.extensions/supergloo created
deployment.extensions/discovery created
deployment.extensions/mesh-discovery created
install successful!
```
Then we can make sure our pods are deployed with `kubectl get pods --all-namespaces`

```
NAMESPACE          NAME                                    READY   STATUS    RESTARTS   AGE
kube-system        coredns-76b964fdc6-2kjp9                1/1     Running   0          41m
kube-system        coredns-76b964fdc6-k7ktf                1/1     Running   0          37m
kube-system        coredns-autoscaler-86849d9999-pdlt6     1/1     Running   0          40m
kube-system        kube-proxy-2ps6g                        1/1     Running   0          37m
kube-system        kube-proxy-46vkd                        1/1     Running   0          37m
kube-system        kube-proxy-lzknd                        1/1     Running   0          38m
kube-system        kube-svc-redirect-2kfjf                 2/2     Running   0          38m
kube-system        kube-svc-redirect-xdtzd                 2/2     Running   0          37m
kube-system        kube-svc-redirect-zc4bk                 2/2     Running   0          37m
kube-system        kubernetes-dashboard-6975779c8c-kfpgc   1/1     Running   1          41m
kube-system        metrics-server-5dd76855f9-d2jf8         1/1     Running   1          41m
kube-system        tunnelfront-6ddfcfb7b9-6k2lf            1/1     Running   0          40m
supergloo-system   discovery-58fdbb95dd-t7b5x              1/1     Running   0          28m
supergloo-system   mesh-discovery-85d655f99d-klcq2         1/1     Running   0          28m
supergloo-system   supergloo-688ff566-t8tkr                1/1     Running   0          28m
```



## Web ui
As I mentioned earlier Super Gloo also has a web front called service mesh hub. So let's install that now have a look at the features available to us. To install the dashboard run the following command
```
kubectl apply -f https://raw.githubusercontent.com/solo-io/service-mesh-hub/master/install/service-mesh-hub.yaml
```

Then we will check to make sure all the pods for the application have started with `kubectl get pods --all-namespaces`

```
NAMESPACE          NAME                                    READY   STATUS    RESTARTS   AGE
kube-system        coredns-76b964fdc6-2kjp9                1/1     Running   0          45m
kube-system        coredns-76b964fdc6-k7ktf                1/1     Running   0          41m
kube-system        coredns-autoscaler-86849d9999-pdlt6     1/1     Running   0          45m
kube-system        kube-proxy-2ps6g                        1/1     Running   0          42m
kube-system        kube-proxy-46vkd                        1/1     Running   0          42m
kube-system        kube-proxy-lzknd                        1/1     Running   0          42m
kube-system        kube-svc-redirect-2kfjf                 2/2     Running   0          42m
kube-system        kube-svc-redirect-xdtzd                 2/2     Running   0          42m
kube-system        kube-svc-redirect-zc4bk                 2/2     Running   0          42m
kube-system        kubernetes-dashboard-6975779c8c-kfpgc   1/1     Running   1          45m
kube-system        metrics-server-5dd76855f9-d2jf8         1/1     Running   1          45m
kube-system        tunnelfront-6ddfcfb7b9-6k2lf            1/1     Running   0          45m
sm-marketplace     discovery-58fdbb95dd-gvbfq              1/1     Running   0          18s
sm-marketplace     mesh-discovery-7d58964d-7vxkn           1/1     Running   0          17s
sm-marketplace     smm-apiserver-6fff94f645-7fvl9          3/3     Running   0          16s
sm-marketplace     smm-operator-797b557cbd-jb4xp           1/1     Running   0          17s
sm-marketplace     supergloo-789cc877b-cbvpj               1/1     Running   0          19s
supergloo-system   discovery-58fdbb95dd-t7b5x              1/1     Running   0          33m
supergloo-system   mesh-discovery-85d655f99d-klcq2         1/1     Running   0          33m
supergloo-system   supergloo-688ff566-t8tkr                1/1     Running   0          33m
```


Now as this dashboard can deploy into your cluster it is not a good idea to have it exposed outside the cluster.  
We will forward the port to our local `kubectl` client and access it on `localhost:8080`
```
kubectl port-forward -n sm-marketplace deploy/smm-apiserver 8080
```

Now that we have forwarded the port we can access the webpage on `localhost:8080`