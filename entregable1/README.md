# Trabajo Grupal - Los Cinco - Infraestructura para TI - NRC: 1396

## Integrantes

Grupo: Los Cinco

| Código    | Nombre Completo                  |
| --------- | -------------------------------- |
| T00064084 | Paula Andrea Márquez Orlando     |
| T00067622 | Mauro Alonso Gonzalez Figueroa   |
| T00067699 | Juan Diego Perez Navarro         |
| T00068226 | Diederik Antonio Montaño Burbano |
| T00070568 | Omar David Barrios de Alba       |

## Enunciado

Usar Terraform para aprovisionar una máquina virtual (Instancia EC2) con Ubuntu 22.04 LTS y usar Ansible para configurarla como servidor Nginx con PHP. Usar como base los ejemplos publicados en el curso para cada herramienta.

La máquina deberá ser accesible desde Internet a través de su dirección IP pública (tanto para administrarla como para el acceso web - puerto 80).

## Entregables

* Archivos de código fuente IaC de Terraform para el aprovisionamiento de la máquina.
* Archivos de código fuente de Ansible para la configuración de la máquina.
* Archivos de código fuente de la aplicación PHP de prueba (pueden estar en el mismo directorio que los demás).
* Sugiero tomar todo y comprimir en un único .ZIP y subir el archivo comprimido solamente.

## Scripts

Los scripts encontrados en [scripts/](./scripts/) deben ser ejecutados desde el directorio raíz de este entregable, por ejemplo:

```bash
./scripts/terraform-deploy.sh
```
