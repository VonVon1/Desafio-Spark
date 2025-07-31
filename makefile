# Variáveis configuráveis
NAMESPACE = spark-technical-test-data-platform
SPARK_VALUES = spark/values.yaml
ZEPPELIN_VALUES = corrigir-values/values.yaml
ENV ?= minikube  # Pode ser 'k3d' ou 'minikube'
SPARK_MASTER_URL = spark://spark-master-headless.$(NAMESPACE).svc.cluster.local:7077
SPARK_IMAGE = bitnami/spark:4.0.0-debian-12-r2

ifeq ($(ENV), minikube)
  CONTEXT = minikube
  CLUSTER_IP := $(shell minikube ip)
else
  CONTEXT = k3d-test-cluster
  CLUSTER_IP := 127.0.0.1
endif

ZEPPELIN_INGRESS_HOST := zeppelin.$(CLUSTER_IP).nip.io

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

.PHONY: reset-pods
reset-pods:
	@echo "🧹 Limpando pods do namespace $(NAMESPACE)..."
	kubectl delete pods --all -n $(NAMESPACE) || true

.PHONY: upgrade
upgrade: repo-add set-context create-namespace create-clusterrolebinding reset-pods
	@echo "🚀 Instalando Spark..."
	helm upgrade --install spark bitnami/spark -f $(SPARK_VALUES) \
		-n $(NAMESPACE) \
		--force \
		--debug \
		--set master.readinessProbe.initialDelaySeconds=90 \
		--set image.repository=bitnami/spark \
		--set image.tag=4.0.0-debian-12-r2

	@echo "🚀 Instalando Zeppelin..."
	helm upgrade --install zeppelin ./corrigir-values -f $(ZEPPELIN_VALUES) \
		-n $(NAMESPACE) \
		--force \
		--debug \
		--set interpreter.spark.properties.spark.master=$(SPARK_MASTER_URL) \
		--set interpreter.spark.properties.spark.kubernetes.container.image=$(SPARK_IMAGE) \
		--set ingress.hosts[0].host=$(ZEPPELIN_INGRESS_HOST) \
		--set env.SPARK_MASTER=$(SPARK_MASTER_URL)

.PHONY: deploy-all
deploy-all: upgrade

.PHONY: get-info
get-info:
	@echo "\nSpark Master UI:"
	@kubectl port-forward -n $(NAMESPACE) svc/spark-master-headless 7077:7077 &
	@echo "→ Spark Cluster: spark://spark-master-headless.$(NAMESPACE).svc.cluster.local:7077"
	@echo "\nZeppelin UI:"
	@echo "→ http://$(ZEPPELIN_INGRESS_HOST)"







