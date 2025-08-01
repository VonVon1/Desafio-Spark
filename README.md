# Desafio - Ambiente Apache Zeppelin + Spark em Kubernetes via Minikube

Este repositório contém o provisionamento e configuração de um ambiente Apache Zeppelin integrado ao Apache Spark dentro de um cluster Kubernetes local utilizando Minikube com WSL2. O objetivo é validar a comunicação entre Zeppelin e Spark, expondo a interface via Ngrok.

## 📁 Estrutura do Projeto

- **Helm**: Utilizado para deploy dos charts do Spark e Zeppelin
- **Makefile**: Automatiza os comandos de instalação
- **Minikube**: Ambiente local de Kubernetes
- **Ngrok**: Expõe localmente o Zeppelin para acesso externo via túnel seguro

## ✅ Etapas e Evidências

1. **Verificação dos Pods e Ingress**  
📷 `01_pods_e_ingress.png`

2. **kubectl get all**  
📷 `02_get_all.png`

3. **Service Accounts**  
📷 `03_service_accounts.png`

4. **Port Forward do Zeppelin**  
📷 `04_port_forward.png`

5. **Acesso via Ngrok (comando)**  
📷 `05_ngrok_comando.png`

6. **Tunnel Criado com Ngrok (output)**  
📷 `06_ngrok_output.png`

7. **Requisição Curl PowerShell no Zeppelin**  
📷 `07_curl_powershell.png`

8. **Interpreter do Zeppelin configurado**  
📷 `08_interpreter_zeppelin.png`

9. **Tela do Zeppelin com Spark configurado**  
📷 `09_spark_no_zeppelin.png`

10. **CI CD Workflow print**  
📷 `CI CD workflow.png`

## 🚀 Como rodar

1. Suba o Minikube com `minikube start`
2. Execute `make deploy`
3. Aguarde os pods estarem `Running`
4. Rode `kubectl port-forward` para o Zeppelin
5. Em outro terminal, rode `ngrok http`
6. Acesse o link gerado

## 🧠 Observações

- Uso de `nip.io` facilita acesso no Minikube
- `ngrok` + `port-forward` essencial no WSL2

## 📸 Galeria de Evidências

Imagens salvas no diretório `/resolutions` 
Pipeline dentro da pasta `./.github/workflows/deploy.yaml e /pipeline`

OBS: O values.yaml usado do zeppelin se encontra na pasta de chart corrigir-values logo a que esta na pasta zeppelin nao esta sendo usado pois trouxe o repo do chart oficial pra mudar algumas confs.
O do spark continua no mesmo lugar.

