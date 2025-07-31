# Variáveis configuráveis
NAMESPACE = spark-technical-test-data-platform
SPARK_RELEASE = spark
ZEPPELIN_RELEASE = zeppelin
SPARK_VALUES = spark/values.yaml
ZEPPELIN_VALUES = corrigir-values/values.yaml
ENV ?= minikube  # Pode ser 'k3d' ou 'minikube'
SPARK_MASTER_URL = spark://spark-master-headless.$(NAMESPACE).svc.cluster.local:7077
SPARK_IMAGE = bitnami/spark:4.0.0-debian-12-r2

ifeq ($(ENV), minikube)
  CONTEXT = minikube
  MINIKUBE_IP := $(shell minikube ip)
else
  CONTEXT = k3d-test-cluster
  MINIKUBE_IP := 127.0.0.1
endif

# Zeppelin Ingress DNS format zeppelin.{minikube-ip}.nip.io
ZEPPELIN_INGRESS_HOST = zeppelin.$(MINIKUBE_IP).nip.io

.PHONY: repo-add
repo-add:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add duyet https://duyet.github.io/charts || true
	helm repo update

.PHONY: set-context
set-context:
	kubectl config use-context $(CONTEXT)

.PHONY: create-namespace
create-namespace:
	kubectl create namespace $(NAMESPACE) || true

.PHONY: create-clusterrolebinding
create-clusterrolebinding:
	kubectl create clusterrolebinding zeppelin-cluster-admin-binding \
	--clusterrole=cluster-admin \
	--serviceaccount=$(NAMESPACE):zeppelin || true

.PHONY: patch-values
patch-values:
ifeq ($(ENV), minikube)
	@echo "🔧 Ambiente minikube detectado. Substituindo {minikube-ip} por $(MINIKUBE_IP)..."
	sed -i 's/{minikube-ip}/$(MINIKUBE_IP)/g' $(ZEPPELIN_VALUES)
else
	@echo "🔧 Ambiente $(ENV) detectado. Substituindo {minikube-ip} por 127.0.0.1..."
	sed -i 's/{minikube-ip}/127.0.0.1/g' $(ZEPPELIN_VALUES)
endif


.PHONY: uninstall
uninstall:
	@echo "🧹 Removendo releases Helm do namespace $(NAMESPACE)..."
	-helm uninstall $(SPARK_RELEASE) -n $(NAMESPACE) || true
	-helm uninstall $(ZEPPELIN_RELEASE) -n $(NAMESPACE) || true
	@echo "🕒 Aguardando 60 segundos para garantir que os recursos sejam totalmente limpos..."
	sleep 60
	@echo "✅ Remoção concluída."

.PHONY: upgrade
upgrade: repo-add set-context create-namespace create-clusterrolebinding uninstall patch-values
	@echo "🚀 Instalando Spark..."
	helm upgrade --install $(SPARK_RELEASE) bitnami/spark -f $(SPARK_VALUES) \
		-n $(NAMESPACE) \
		--force \
		--debug \
		--set master.readinessProbe.initialDelaySeconds=90 \
		--set image.repository=bitnami/spark \
		--set image.tag=4.0.0-debian-12-r2

	@echo "🚀 Instalando Zeppelin..."
	helm upgrade --install $(ZEPPELIN_RELEASE) ./corrigir-values -f $(ZEPPELIN_VALUES) \
		-n $(NAMESPACE) \
		--force \
		--debug \
		--set interpreter.spark.properties.spark.master=$(SPARK_MASTER_URL) \
		--set interpreter.spark.properties.spark.kubernetes.container.image=$(SPARK_IMAGE) \
		--set ingress.hosts[0].host=$(ZEPPELIN_INGRESS_HOST) \
		--set env.SPARK_MASTER=$(SPARK_MASTER_URL)

.PHONY: deploy-all
deploy-all: upgrade











