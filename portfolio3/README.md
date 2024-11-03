
# Portfolio 3

In dit portfolio 3 is een Kubernetes-cluster opgezet in Proxmox. Het cluster bevat een Helm-managed Apache-server, een PostgreSQL-database met Adminer in een aparte namespace, een Ingress-controller, monitoring met Prometheus, en autoscaling met KEDA.

## Inhoudsopgave
1. [Minikube Installatie](#minikube-installatie)
2. [Helm Installatie en Apache Server Deployen](#helm-installatie-en-apache-server-deployen)
3. [Database en Adminer Interface](#database-en-adminer-interface)
4. [Apache Server met Ingress en ConfigMap](#apache-server-met-ingress-en-configmap)
5. [GitOps met ArgoCD](#gitops-met-argocd)
6. [Monitoring met Prometheus](#monitoring-met-prometheus)
7. [Autoscaling met KEDA](#autoscaling-met-keda)
8. [Screenshots](#screenshots)

---

### 1. Minikube Installatie
Voor de installatie van Minikube:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

minikube start --driver=docker
alias kubectl="minikube kubectl --"
```

### 2. Helm Installatie en Apache Server Deployen
Installeer Helm en configureer een Apache-server met een Helm chart:

1. **Helm installeren:**
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
   helm create apache-server
   cd apache-server
   ```

2. **Pas `values.yaml` aan:**
   ```yaml
   replicaCount: 1
   image:
     repository: httpd
     pullPolicy: IfNotPresent
     tag: "2.4"
   service:
     type: ClusterIP
     port: 80
   config:
     serverName: "localhost"
     listenPort: 80
     documentRoot: "/usr/local/apache2/htdocs"
   ```

3. **Voeg de configuratie toe aan `templates/deployment.yaml`:**
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: {{ .Release.Name }}-apache-server
   spec:
     replicas: {{ .Values.replicaCount }}
     selector:
       matchLabels:
         app: {{ .Release.Name }}-apache-server
     template:
       metadata:
         labels:
           app: {{ .Release.Name }}-apache-server
       spec:
         containers:
           - name: apache
             image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
             ports:
               - containerPort: 80
   ```

4. **Pas dit toe aan `templates/service.yaml`:**
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: {{ .Release.Name }}-apache-service
   spec:
     type: {{ .Values.service.type }}
     ports:
       - port: {{ .Values.service.port }}
         targetPort: 80
     selector:
       app: {{ .Release.Name }}-apache-server
   ```

5. **Installeer de Apache-server:**
   ```bash
   helm install my-apache ./apache-server
   kubectl get pods
   kubectl get svc
   ```

6. **Externe toegang testen:**
   ```bash
   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=apache-server,app.kubernetes.io/instance=my-apache" -o jsonpath="{.items[0].metadata.name}")
   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")

   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
   curl http://127.0.0.1:8080
   ```

### 3. Database en Adminer Interface
Configureer een PostgreSQL-database en Adminer in een aparte namespace:

1. **Creëer namespace en PersistentVolume:**
   ```bash
   minikube kubectl -- create namespace db-namespace
   mkdir database
   cd database
   ```

2. **Maak `db-pv.yaml` aan:**
   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: db-pv
   spec:
     capacity:
       storage: 1Gi
     accessModes:
       - ReadWriteOnce
     hostPath:
       path: "/mnt/data/db"  # Lokaal pad op de Minikube VM
   ```

3. **Maak `db-pvc.yaml` aan:**
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: db-pvc
     namespace: db-namespace
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 1Gi
   ```

4. **Maak `db-deployment.yaml` aan:**
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: postgres-db
     namespace: db-namespace
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: postgres-db
     template:
       metadata:
         labels:
           app: postgres-db
       spec:
         containers:
           - name: postgres
             image: postgres:13
             ports:
               - containerPort: 5432
             env:
               - name: POSTGRES_USER
                 value: "admin"
               - name: POSTGRES_PASSWORD
                 value: "password"
               - name: POSTGRES_DB
                 value: "mydatabase"
             volumeMounts:
               - mountPath: /var/lib/postgresql/data
                 name: db-storage
       volumes:
         - name: db-storage
           persistentVolumeClaim:
             claimName: db-pvc
   ```

5. **Maak `db-service.yaml` aan:**
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: postgres-service
     namespace: db-namespace
   spec:
     type: ClusterIP
     ports:
       - port: 5432
         targetPort: 5432
     selector:
       app: postgres-db
   ```

6. **Voer de configuraties uit:**
   ```bash
   minikube kubectl -- apply -f db-pv.yaml
   minikube kubectl -- apply -f db-pvc.yaml
   minikube kubectl -- apply -f db-deployment.yaml
   minikube kubectl -- apply -f db-service.yaml
   ```

7. **Definieer `adminer-deployment.yaml`:**
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: adminer
     namespace: db-namespace
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: adminer
     template:
       metadata:
         labels:
           app: adminer
       spec:
         containers:
           - name: adminer
             image: adminer
             ports:
               - containerPort: 8080
   ```

8. **Definieer `adminer-service.yaml`:**
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: adminer-service
     namespace: db-namespace
   spec:
     type: ClusterIP
     ports:
       - port: 8080
         targetPort: 8080
     selector:
       app: adminer
   ```

9. **Voer de configuraties uit:**
   ```bash
   minikube kubectl -- apply -f adminer-deployment.yaml
   minikube kubectl -- apply -f adminer-service.yaml
   ```

10. **Test toegang tot Adminer via port-forwarding:**
    ```bash
    minikube kubectl -- port-forward service/adminer-service 8080:8080 -n db-namespace
    ```

### 4. Apache Server met Ingress en ConfigMap
De Apache-server wordt voorzien van Ingress voor externe toegang en gebruikt ConfigMaps voor contentbeheer.

1. **Ingress addon inschakelen:**
   ```bash
   minikube addons enable ingress
   ```

2. **Pas deployment.yaml aan in de Helm chart:**
  ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: {{ include "apache-server.fullname" . }}
      labels:
        {{- include "apache-server.labels" . | nindent 4 }}
    spec:
      {{- if not .Values.autoscaling.enabled }}
      replicas: {{ .Values.replicaCount }}
      {{- end }}
      selector:
        matchLabels:
          {{- include "apache-server.selectorLabels" . | nindent 6 }}
      template:
        metadata:
          labels:
            {{- include "apache-server.labels" . | nindent 8 }}
          spec:
            containers:
              - name: {{ .Chart.Name }}
                image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
                ports:
                  - name: http
                    containerPort: {{ .Values.service.port }}
                    protocol: TCP
                volumeMounts:
                  - name: apache-config-volume
                    mountPath: /usr/local/apache2/htdocs
            volumes:
              - name: apache-config-volume
                configMap:
                  name: {{ include "apache-server.fullname" . }}-config
  ```

4. **Pas configmap.yaml aan in de Helm chart:**
  ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ include "apache-server.fullname" . }}-config
    data:
      index.html: |
        <html>
          <head><title>Welkom bij Mijn Apache Server</title></head>
          <body><h1>Dit is de homepage voor Mijn Apache Server</h1></body>
        </html>
  ```

5. **Pas values.yaml aan in de Helm chart:**
  ```yaml
    ingress:
      enabled: true
      className: "nginx"
      hosts:
        - host: mijn-apache.local
          paths:
            - path: /
              pathType: Prefix
  ```

5. **Voeg ingress.yaml toe aan de Helm chart:**
```yaml
  {{- if .Values.ingress.enabled -}}
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: my-apache-apache-server
    namespace: apache-namespace
  spec:
    ingressClassName: nginx
    rules:
      - host: mijn-apache.local
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: my-apache-apache-server-service
                  port:
                    number: 80
  {{- end }}
  ```

6. **Deploy de Helm chart:**
   ```bash
    minikube kubectl -- create namespace apache-namespace
    helm install my-apache ./apache-server --namespace apache-namespace
   ```

7. **Test de Ingress configuratie: Voeg het volgende toe aan /etc/hosts::**
   ```yaml
   127.0.0.1    mijn-apache.local
   ```

3. **Test vervolgens met:**
   ```bash
   curl http://mijn-apache.local
   ```

### 5. GitOps met ArgoCD
ArgoCD is geïnstalleerd voor GitOps in de Kubernetes-omgeving.

1. **Maak een namespace voor ArgoCD en installeer de resources:**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl config set-context --current --namespace=argocd
   ```

2. **Installeer de ArgoCD CLI:**
  ```bash
    curl -sSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -o argocd
    chmod +x argocd
    sudo mv argocd /usr/local/bin/
   ```

3. **Controleer of de ArgoCD pods zijn opgestart:**
   ```bash
    kubectl get pods -n argocd
   ```

4. **Inloggen in ArgoCD: Haal het standaard wachtwoord op voor de admin-gebruiker:**
   ```bash
    kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
   ```
   argocd login localhost:8080 --username admin --password

5. **Applicatie deployen via ArgoCD: Maak een voorbeeldapplicatie aan en synchroniseert het**
   ```bash
    argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
    argocd app sync guestbook
   ```   

6. **Testen van de ArgoCD server: Gebruik port-forwarding om toegang te krijgen tot de ArgoCD UI:**
   ```bash
    kubectl port-forward svc/argocd-server -n argocd 8081:443
    sudo socat TCP-LISTEN:8080,fork TCP:127.0.0.1:8081
   ```

### 6. Monitoring met Prometheus
Prometheus is geïnstalleerd voor monitoring van prestaties en beschikbaarheid.

1. **Metrics-server en Prometheus installeren:**
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. **Voeg de Prometheus Helm chart repository toe en werk deze bij:**
   ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
   ```

3. **Schakel de Metrics Server addon in Minikube in:**
   ```bash
   minikube addons enable metrics-server
   ```

4. **Creëer een namespace voor monitoring en installeer Prometheus:**
   ```bash
    kubectl create namespace monitoring
    helm install prometheus prometheus-community/prometheus --namespace monitoring
    kubectl get pods -n monitoring
   ```

5. **Toegang tot Prometheus UI via port-forwarding: Stel port-forwarding in om de Prometheus UI te bereiken:**
   ```bash
    kubectl port-forward svc/prometheus-server -n monitoring 8081:80
    sudo socat TCP-LISTEN:8082,fork TCP:127.0.0.1:8081
   ```

  Je kunt nu de Prometheus UI openen met ip van de Prometheus
  Gebruik de volgende queries in de Prometheus UI om diverse statistieken op te halen:
  ```yaml
  sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod)
  sum(container_memory_usage_bytes{namespace="default"}) by (pod)
  sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)
  kube_pod_status_phase
  ```

### Gebruik dit op een andere terminal en kijk als er extra keda bij zijn gekomen.

### 7. Autoscaling met KEDA
KEDA is geïnstalleerd voor autoscaling op basis van een HTTP-verzoeken threshold.

1. **KEDA installatie:**
   ```bash
   helm repo add kedacore https://kedacore.github.io/charts
   helm repo update
   helm install keda kedacore/keda --namespace keda --create-namespace
   ```

2. **Maak scaleobject voor Apache in apache-server/templates/scaleobject.yaml**
```yaml
  apiVersion: keda.sh/v1alpha1
  kind: ScaledObject
  metadata:
    name: apache-server-scaledobject
    namespace: apache-namespace
  spec:
    scaleTargetRef:
      name: my-apache-apache-server
    minReplicaCount: 1
    maxReplicaCount: 10
    triggers:
      - type: prometheus
        metadata:
          serverAddress: http://prometheus-server.default.svc.cluster.local:9090
          metricName: http_requests_total
          query: sum(rate(http_requests_total[2m]))
          threshold: "100"
```

2. **Test met een load-test:**
```bash
   for i in {1..1000}; do curl http://mijn-apache.local; done
```

### Gebruik dit op een andere terminal en kijk als er extra keda bij zijn gekomen.
```bash
   kubectl get hpa -n apache-namespace
```
---

### Screenshots
Screenshots van de uitkomsten van elke opdracht zijn te vinden in de map `screenshot`.

---


