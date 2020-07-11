# Kong + Keycloak

Esse repositório é um consolidado do artigo:
`(Com ajustes para versão 2.1 do kong e imagem quay.io do keycloak)`

[Securing APIs with Kong and Keycloak](https://www.jerney.io/secure-apis-kong-keycloak-1/) de Joshua A. Erney

Deixo aqui meu agradecimento pessoal ao Joshua por esse artigo esclarecedor.

## Configuração do ambiente

```sh
#!/bin/bash

# Subir banco de dados do kong 
docker-compose up -d kong_db

# Rodar as migrations do kong
docker-compose run --rm kong kong migrations bootstrap

# Subir container do kong e konga
docker-compose up -d kong
docker-compose up -d konga

# Subir banco do keycloak
docker-compose up -d keycloak_db

# Subir container do keycloak
docker-compose up -d keycloak
```

### Configuração do Kong

[JSON Processor cli - jq](https://stedolan.github.io/jq/)

Os steps a seguir podem ser realizados via interface REST do kong ou Konga UI.

1. Criar o serviço
1. Criar a(s) rota(s) do serviço

```sh
#!/bin/bash

export KONG_ADMIN_HOST="http://localhost:8001"

export SERVICE_NAME="my-service"
export SERVICE_URL="my-service-url"
export SERVICE_ROUTE="/my-route"

# Criar serviço no kong
$service_id=$(curl -s -X POST ${KONG_ADMIN_HOST}/services \
    -d name=${SERVICE_NAME} \
    -d url=${SERVICE_URL} | jq .id)

# Criar rota no kong
curl -s -X POST ${KONG_ADMIN_HOST}/routes \
    -d service.id=${service_id} \
    -d paths[]=${SERVICE_ROUTE}
```

### Configuração do Keycloak (Tela de login)

1. Adicionar o usuário admin inicial através do script abaixo (Essa abordagem evita o erro de usuário já está cadastrado no momento de subir o container utilizando as variáveis de ambiente `KEYCLOAK_USER` e `KEYCLOAK_PASSWORD` no docker)

```sh
#!/bin/bash

export KK_USER="admin"
export KK_PASS="admin"

# Criar usuário inicial no keycloak
docker exec keycloak /opt/jboss/keycloak/bin/add-user-keycloak.sh -u ${KK_USER} -p ${KK_PASS}
```

1. Criar um client com `Access Type` confidential (Guardar o Secret gerado na aba `Credentials` para os próximos passos) 
1. Adicionar um usuário
1. Configurar keycloak no `KongOIDC Plugin`

```sh
#!/bin/bash

# Configura Keycloak no KongOIDC Plugin

export KONG_ADMIN_HOST="http://localhost:8001"

# Kong não consegue acessar localhost, deve-se utilizar o ip real da máquina
export HOST="http://192.168.0.1:8080"

export KK_CLIENT_ID="client id"
export KK_CLIENT_SECRET="client secret"

curl -s -X POST ${KONG_ADMIN_HOST}/plugins \
  -d name=oidc \
  -d config.client_id=${KK_CLIENT_ID} \
  -d config.client_secret=${KK_CLIENT_SECRET} \
  -d config.discovery=${HOST}/auth/realms/master/.well-known/openid-configuration
```