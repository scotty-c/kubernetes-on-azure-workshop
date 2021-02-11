# Kubernetes on Azure

This is the repo that contains multiple workshops for Kubernetes on Azure and the supporting code examples.
Note This repo is under a refresh. Some of the new modules dont have slides yet.

## Prerequisites

### Prior knowledge 
To be successful at getting the most out of these workshops you will need the following prior knowledge

* A basic understanding of Linux
* Be able to read bash scripts
* Have a basic knowledge of what a container is 

### Equipment
To be able to run the labs in the workshops you will need the following 

* An Azure account that has access to create service principals

If you dont have an Azure account and want to run the workshops, you can sign up for an [Azure trial](https://azure.microsoft.com/offers/ms-azr-0044p/?WT.mc_id=opensource-0000-sccoulto) that will give you free credit to complete the workshop.

### Installed software
There are a few packages we will need to run the labs so we will need to install the following

* [Docker](https://www.docker.com/)

There is a pre built docker image with all the software that you need.
 
## How to use the workshops

Pull and run the docker image  
 ```
 docker run -d --privileged --name workshop scottyc/workshop && docker exec -it workshop sh
 ```  
if you want to keep the data from the workshop persistent, you can use the following  
```  
docker run -d --privileged -v {SOME_DIR}:/workshop --name workshop scottyc/workshop && docker exec -it workshop sh
```   
git clone the workshop 
```git clone https://github.com/scotty-c/kubernetes-on-azure-workshop.git```  
Now from inside the containers shell login to the az cli with `az login` and follow the prompts.

Each folder is named after a corresponding module in the workshop. Inside that folder is all the code examples for that module.

Alternatively if you are running vscode and have the [remote container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers%2F%3FWT.mc_id%3Daksworkshop-github-sccoulto&WT.mc_id=opensource-0000-sccoulto) you can just open up a folder in the remote container.

## Workshops 

At present there are four workshops in this repo. Each of them are designed for different lengths of time depending how long your time slot is to give the workshop.

### Kubernetes on Azure full workshop
This is the full workshop that covers Kubernetes 101, Helm, virtual kubelet and some basic istio topic. Below are the full list of topics

 Kubernetes 101

* [Agenda](slides/intro/code.md) 
* [Introduction into Kubernetes](slides/introduction-into-kubernetes/code.md)
* [Kubernetes components](slides/kubernetes-components/code.md) 
* [Deploying Kubernetes on Azure](deploying-kubernetes-on-azure/code.md)
* [Pods, services and deployments](pods-services-deployments/code.md)
* [Rabc, roles and service accounts](rbac-roles-service-accounts/code.md) 
* [Stateful sets](statefull-sets/code.md)
* Kubernetes networking and service discovery
* [Load balancing and ingress control](ingress-controller/code.md)

 Helm

* Introduction into Helm
* Understanding charts
* [Deploying Helm on Kubernetes](installing-helm-on-kubernetes/code.md)
* Helm cli
* [Deploying a public chart](deploying-a-public-chart/code.md)
* [Writing our own chart](writing-our-own-chart/code.md)
* Helm and CNAB

 Kubernetes advanced topics

* [Virtual kubelet](virtual-node-with-virtual-kubelet/code.md)
* [Pod security context](pod-security-policy/code.md) 
* Introduction to istio
* Advanced application routing with istio(advanced-application-routing-with-istio/code.md)
* [Setting mTLS between application services with istio](mTLS-with-istio/code.md) 

This workshop takes about 6hrs to give as instructor lead workshop.  


### Kubernetes 101
This workshop is the entry level into Azure Kubernetes service. In the workshop we will cover the topics listed above in the kubernetes 101 section. This will take approx 2hrs for an instructor to give.  

### Kubernetes and Helm 
This workshop covers the kubernetes 101 workshop and adds all the Helm modules listed above. 
The slides can be found [here](slides/kubernetes-helm/Kubernetes-helm.pdf).  
This workshop will take about 4hrs to complete  

### Advanced Kubernetes
This workshop adds the Kubernetes 101 modules with the advanced Kubernetes topics.  
The slides can be found [here](slides/kubernetes-advanced/Kubernetes-advanced.pdf)  
This workshop will take about 4hrs   

## Further reading
I have done a few blog posts on topics covered by this workshop for further . This list will continue to be updated.
* [Choosing the right container base image](https://dev.to/scottyc/i-cho-cho-chose-you-container-image-part-1-227p)
* [Pod security 101](https://medium.com/devopslinks/kubernetes-pod-security-101-15fe8cda829e)
* [Understading application routing with istio](https://itnext.io/understanding-application-routing-in-istio-aade30d594f4)

If there is something that is not covered in the workshops and you would like it to be. Please raise an issue on this repo and I will do my best to add it in where possible

