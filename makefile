# Variáveis configuráveis
NAMESPACE = spark-technical-test-data-platform
SPARK_VALUES = spark/values.yaml
ZEPPELIN_VALUES = corrigir-values/values.yaml
#ZEPPELIN_TEMP_VALUES = corrigir-values-temp/values-temp.yaml

# Host fixo para uso com K3D (nip.io resolve 127.0.0.1)
ZEPPELIN_INGRESS_HOST := zeppelin.127.0.0.1.nip.io

# Atualiza e adiciona repositórios Helm necessários
.PHONY: repo-add
repo-add:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add duyet https://duyet.github.io/charts || true
	helm repo update

# Cria o namespace necessário
.PHONY: local-namespace
local-namespace:
	kubectl config use-context k3d-test-cluster
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
#	@echo "    - host: zeppelin.127.0.0.1.nip.io" >> $(ZEPPELIN_TEMP_VALUES)
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

# Aguarda os pods ficarem prontos com timeout
.PHONY: wait-pods
wait-pods:
	@echo "⏳ Aguardando pods ficarem prontos..."
	@kubectl wait --for=condition=Ready pods --all -n $(NAMESPACE) --timeout=600s || \
	( echo "❌ Timeout esperando pods. Mostrando eventos:" && \
	kubectl get pods -n $(NAMESPACE) && \
	kubectl describe pods -n $(NAMESPACE) && \
	exit 1 )

# Mostra informações úteis (pods, eventos e logs iniciais)
.PHONY: check-pods
check-pods:
	@echo "📦 Pods:"
	@kubectl get pods -n $(NAMESPACE)
	@echo "📜 Eventos:"
	@kubectl get events -n $(NAMESPACE) --sort-by='.metadata.creationTimestamp'
	@echo "📄 Logs iniciais:"
	@for pod in $$(kubectl get pods -n $(NAMESPACE) -o jsonpath='{.items[*].metadata.name}'); do \
		echo "--- pod/$$pod ---"; \
		kubectl logs $$pod -n $(NAMESPACE) --tail=30 || echo "Sem logs disponíveis ainda."; \
	done

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




