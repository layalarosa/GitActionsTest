# GitActionsTest

Proyecto de prueba para servir un archivo HTML desde un contenedor Docker y validar la imagen con GitHub Actions.

## Archivos principales

- `index.html`: pagina HTML de prueba.
- `Dockerfile`: imagen basada en `nginx:1.27-alpine` que sirve el HTML.
- `.dockerignore`: excluye archivos innecesarios del contexto de Docker.
- `.github/workflows/docker-html.yml`: workflow de GitHub Actions que construye y prueba el contenedor.

## Como funciona

El contenedor usa Nginx para servir `index.html` desde:

```text
/usr/share/nginx/html/index.html
```

La GitHub Action se ejecuta en:

- Cada `push`.
- Cada `pull_request`.
- Ejecucion manual desde la pestaña Actions con `workflow_dispatch`.

El workflow hace estos pasos:

1. Descarga el codigo del repositorio.
2. Construye la imagen Docker.
3. Ejecuta el contenedor en el puerto `8080`.
4. Hace una peticion HTTP a `http://localhost:8080`.
5. Verifica que la respuesta contiene el texto `HTML de prueba en Docker`.
6. Elimina el contenedor al final, incluso si la prueba falla.

## Ejecutar localmente

Construir la imagen:

```powershell
docker build -t docker-html-test:local .
```

Ejecutar el contenedor:

```powershell
docker run -d --name docker-html-test-local -p 8080:80 docker-html-test:local
```

Abrir en el navegador:

```text
http://localhost:8080
```

Detener y eliminar el contenedor:

```powershell
docker rm -f docker-html-test-local
```

## GitHub Actions

El workflow esta en:

```text
.github/workflows/docker-html.yml
```

La ejecucion valida que Docker puede construir la imagen y que el HTML se sirve correctamente desde el contenedor.

Importante: esta Action no publica una pagina web ni deja un contenedor corriendo en internet. Solo construye y prueba el contenedor dentro del runner de GitHub Actions.

## Publicar el HTML

Si quieres que el HTML sea visible como una pagina publica, usa GitHub Pages.

Si quieres publicar la imagen Docker, puedes agregar un workflow para subirla a GitHub Container Registry (`ghcr.io`) o Docker Hub.
