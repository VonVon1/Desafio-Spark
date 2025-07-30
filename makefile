# Variáveis configuráveis
NAMESPACE = spark-technical-test-data-platform
SPARK_VALUES = spark/values.yaml
ZEPPELIN_VALUES = corrigir-values/values.yaml
#ZEPPELIN_TEMP_VALUES = corrigir-values-temp/values-temp.yaml

# Descobre IP para o Ingress com fallback para localhost
ZEPPELIN_INGRESS_HOST := zeppelin.$(shell \
	kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
	echo "127.0.0.1").nip.io

# Atualiza e adiciona repositórios Helm necessários
.PHONY: repo-add
repo-add:
	helm repo update
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add duyet https://duyet.github.io/charts || true

# Cria o namespace necessário
.PHONY: local-namespace
local-namespace:
	kubectl config use-context docker-desktop
	kubectl create namespace $(NAMESPACE) || true

# Cria o clusterrolebinding para o Zeppelin
.PHONY: local-clusterrolebinding
local-clusterrolebinding:
	kubectl create clusterrolebinding zeppelin-cluster-admin-binding \
	--clusterrole=cluster-admin \
	--serviceaccount=$(NAMESPACE):zeppelin || true

# Gera values.yaml corrigido para Zeppelin com ingress válido e serviceAccount
#.PHONY: prepare-zeppelin-values
#prepare-zeppelin-values:
#	@echo "🛠️  Preparando valores do Zeppelin..."
#	@mkdir -p zeppelin
#	@echo "ingress:" > $(ZEPPELIN_TEMP_VALUES)
#	@echo "  enabled: true" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "  annotations:" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "    kubernetes.io/ingress.class: nginx" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "  hosts:" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "    - host: zeppelin.$$(echo 127.0.0.1).nip.io" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "      paths:" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "        - path: /" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "          pathType: Prefix" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "  tls: []" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "serviceAccount:" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "  create: true" >> $(ZEPPELIN_TEMP_VALUES)
#	@echo "Valores temporários gerados em $(ZEPPELIN_TEMP_VALUES)"

# Instala/atualiza os componentes do Spark e Zeppelin
.PHONY: local-upgrade
local-upgrade: repo-add local-namespace local-clusterrolebinding 
	@echo "🚀 Instalando Spark..."
	helm upgrade --install spark bitnami/spark -f $(SPARK_VALUES) -n $(NAMESPACE) --debug
	@echo "🚀 Instalando Zeppelin..."
	helm upgrade --install zeppelin ./corrigir-values -f $(ZEPPELIN_VALUES) -n $(NAMESPACE) --debug

# Comando completo para implantação local
.PHONY: deploy-all
deploy-all: local-upgrade

# Mostra informações de acesso
.PHONY: get-info
get-info:
	@echo "\nSpark Master UI:"
	@kubectl port-forward -n $(NAMESPACE) svc/spark-master-svc 80:80 &
	@echo "→ http://127.0.0.1:80"
	@echo "\nZeppelin UI:"
	@echo "→ http://$(ZEPPELIN_INGRESS_HOST)"



