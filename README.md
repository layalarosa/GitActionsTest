# GitActionsTest

Proyecto demo de arquitectura moderna con contenedores, CI/CD, infraestructura como codigo y despliegue automatizado.

## Arquitectura

```text
                         +-----------+
                         |  Usuario  |
                         +-----+-----+
                               |
                        80 (HTTP)
                               |
                    +----------v----------+
                    |       Nginx         |
                    | (reverse proxy +    |
                    |  static files)      |
                    +----+----------+-----+
                         |          |
                    /api/*         /*
                         |          |
              +----------v--+    sirve index.html
              |  Express API |    desde el build
              |  (Node.js)   |    multi-stage
              +-------+-----+
                      |
                5432 (TCP)
                      |
              +-------v------+
              |  PostgreSQL   |
              |  (datos)      |
              +--------------+
```

### Componentes

| Componente | Tecnologia | Funcion |
|------------|-----------|---------|
| Frontend | HTML + CSS + JS (minificados) | UI estatica con informacion del sistema |
| Proxy | Nginx 1.27 | Sirve archivos estaticos y redirige `/api/*` al backend |
| API | Node.js / Express 4 | REST API con endpoints `/api/health`, `/api/items` |
| Base de datos | PostgreSQL 16 | Persistencia de datos |

## Buenas practicas implementadas

### 1. Multi-stage Docker build (`Dockerfile`)

Construccion en dos etapas:

- **Stage 1 (`node:22-alpine`)**: Minifica HTML/CSS con `html-minifier` y genera un archivo `version.txt` con el timestamp del build.
- **Stage 2 (`nginx:1.27-alpine`)**: Solo copia los assets compilados y el config de Nginx. La imagen final es minima y no contiene herramientas de build.

Beneficios: imagenes mas pequenas, menor superficie de ataque, separacion de responsabilidades.

### 2. Multi-servicio con Docker Compose (`docker-compose.yml`)

Orquestacion local de los 3 servicios:

```powershell
docker compose up -d
```

Cada servicio incluye:
- **Healthchecks** automaticos para garantizar dependencias.
- **Red interna** (`app-net`) para comunicacion aislada.
- **Volumen** persistente para la base de datos.

### 3. API REST con Express y PostgreSQL (`api/`)

Endpoints disponibles:

| Metodo | Ruta | Descripcion |
|--------|------|-------------|
| `GET` | `/api/health` | Healthcheck con estado de DB |
| `GET` | `/api/items` | Lista todos los items |
| `POST` | `/api/items` | Crea un nuevo item |

### 4. CI/CD Pipeline (`docker-html.yml`)

El pipeline de GitHub Actions tiene 4 jobs secuenciales:

```text
security-scan --> build-and-test --> publish --> deploy
```

**security-scan**: Escanea el Dockerfile con **Trivy** en busca de vulnerabilidades HIGH/CRITICAL. Sube resultados en formato SARIF a GitHub Security.

**build-and-test**: Construye las imagenes con cache de GitHub Actions, levanta los servicios con docker-compose, espera healthchecks, y ejecuta pruebas de integracion.

**publish** (solo en push a `main` o tags): Etiqueta las imagenes con metadata semantica (`latest`, `v1.2.3`, `sha-xxxx`) y las publica en **GitHub Container Registry (GHCR)**.

**deploy** (solo en tags `v*`): Ejecuta Terraform para desplegar en Azure Container Instances.

### 5. Escaneo de seguridad con Trivy

El job `security-scan` analiza la configuracion de Dockerfile en busca de:
- Vulnerabilidades en imagenes base
- Exposicion de puertos innecesarios
- Ejecucion como root
- Malas practicas de seguridad

Los resultados aparecen en la pestana **Security** del repositorio.

### 6. Publicacion en GitHub Container Registry

Las imagenes se publican automaticamente en `ghcr.io/<usuario>/<repo>` con los siguientes tags:

- `latest` (en push a `main`)
- `vX.Y.Z`, `vX.Y` (en tags semanticos)
- `sha-<commit>` (siempre)

### 7. Versionado semantico automatico

El workflow usa `docker/metadata-action` para generar tags basados en:

- Tags de git con formato `v1.2.3` generan `1.2.3`, `1.2`, `latest`.
- Push a `main` genera `latest` y `sha-<hash>`.
- Pull requests solo ejecutan escaneo y pruebas (no publican).

### 8. Despliegue con Terraform (`terraform/`)

Infraestructura como codigo para Azure:

```text
terraform/
  main.tf      - Resources: Resource Group, ACR, Container Group
  variables.tf - Variables configurables
  outputs.tf   - Outputs: FQDN, ACR URL, RG name
```

El despliegue provisiona:
- **Azure Container Registry** para almacenar las imagenes.
- **Azure Container Instances** para ejecutar nginx + api + db.
- DNS label para acceso publico via FQDN.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con WSL2
- PowerShell 5.1+ (Windows) o bash (Linux/Mac)
- Para Terraform: [Terraform CLI](https://developer.hashicorp.com/terraform/install) >= 1.6
- Para Azure: `az login` con cuenta activa

## Uso local

### Construir y ejecutar todo el stack

```powershell
docker compose up -d --build
```

### Verificar healthchecks

```powershell
docker compose ps
curl http://localhost:80/api/health
```

### Pruebas de integracion manuales

```powershell
# Probar HTML
curl http://localhost:80/ | Select-String "Arquitectura"

# Probar API
curl http://localhost:80/api/items

# Crear item
curl -X POST http://localhost:80/api/items -H "Content-Type: application/json" -d '{"name":"Demo","description":"test"}'
```

### Ejecutar pruebas automatizadas

```powershell
scripts\integration-test.sh
```

### Detener y limpiar

```powershell
docker compose down -v
```

## CI/CD

### Workflow completo

El archivo `.github/workflows/docker-html.yml` orquesta el pipeline completo:

1. **Push a `main`**: Trivy scan -> Build + test -> Publicar a GHCR
2. **Tag `v*`**: Todo lo anterior + Terraform apply en Azure
3. **Pull request**: Trivy scan -> Build + test (sin publicar)
4. **Manual** (`workflow_dispatch`): Igual que push a main

### Secrets necesarios para deploy

Para que el job `deploy` funcione, agregar estos secrets en GitHub:

| Secret | Descripcion |
|--------|-------------|
| `AZURE_SUBSCRIPTION_ID` | ID de suscripcion de Azure |
| `AZURE_CLIENT_ID` | Service principal (app registration) |
| `AZURE_CLIENT_SECRET` | Clave del service principal |
| `AZURE_TENANT_ID` | ID del tenant de Azure |

### Despliegue manual con Terraform

```powershell
cd terraform
terraform init
terraform plan -var image_tag=latest
terraform apply -auto-approve
```

## Estructura del proyecto

```text
.
├── .github/workflows/docker-html.yml   # Pipeline CI/CD completo
├── api/
│   ├── Dockerfile                       # Build multi-stage de la API
│   ├── package.json                     # Dependencias Node.js
│   └── server.js                        # API Express con PostgreSQL
├── db/
│   └── init.sql                         # Script de inicializacion de DB
├── nginx/
│   └── default.conf                     # Config de reverse proxy
├── scripts/
│   └── integration-test.sh              # Pruebas automatizadas
├── terraform/
│   ├── main.tf                          # Infraestructura Azure
│   ├── variables.tf                     # Variables de Terraform
│   └── outputs.tf                       # Outputs del deploy
├── Dockerfile                           # Build multi-stage frontend
├── docker-compose.yml                   # Orquestacion local
├── index.html                           # Frontend (minificado en build)
└── README.md
```
