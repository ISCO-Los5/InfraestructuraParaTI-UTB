#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar prerrequisitos
check_prerequisites() {
    log_info "Verificando prerrequisitos..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform no está instalado"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI no está instalado"
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible no está instalado"
        exit 1
    fi
    
    log_info "✓ Todos los prerrequisitos están instalados"
}

# Verificar login de Azure
check_azure_login() {
    log_info "Verificando login de Azure..."
    
    if ! az account show &> /dev/null; then
        log_error "No estás logueado en Azure"
        log_info "Ejecuta: az login"
        exit 1
    fi
    
    SUBSCRIPTION=$(az account show --query name -o tsv)
    log_info "✓ Conectado a Azure - Suscripción: $SUBSCRIPTION"
}

# Verificar archivo de variables
check_tfvars() {
    log_info "Verificando terraform.tfvars..."
    
    if [ ! -f "terraform.tfvars" ]; then
        log_error "No se encontró terraform.tfvars"
        log_info "Copia terraform.tfvars.example y configúralo:"
        log_info "  cp terraform.tfvars.example terraform.tfvars"
        log_info "  nano terraform.tfvars"
        exit 1
    fi
    
    # Verificar que no tiene valores de ejemplo
    if grep -q "TU_IP_PUBLICA" terraform.tfvars; then
        log_error "terraform.tfvars contiene valores de ejemplo"
        log_info "Edita el archivo y reemplaza los valores"
        exit 1
    fi
    
    log_info "✓ terraform.tfvars configurado correctamente"
}

# Obtener IP pública
get_public_ip() {
    log_info "Obteniendo tu IP pública..."
    MY_IP=$(curl -s ifconfig.me)
    log_info "Tu IP pública es: $MY_IP"
    
    # Verificar si está en terraform.tfvars
    if ! grep -q "$MY_IP" terraform.tfvars; then
        log_warn "Tu IP pública no coincide con la de terraform.tfvars"
        read -p "¿Actualizar terraform.tfvars con tu IP actual? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i.bak "s/controller_ip = \".*\"/controller_ip = \"$MY_IP\/32\"/" terraform.tfvars
            log_info "✓ terraform.tfvars actualizado"
        fi
    fi
}

# Crear directorios necesarios
create_directories() {
    log_info "Creando directorios necesarios..."
    mkdir -p ssh_keys
    mkdir -p scripts
    mkdir -p ansible
    log_info "✓ Directorios creados"
}

# Terraform init
terraform_init() {
    log_info "Inicializando Terraform..."
    terraform init
    log_info "✓ Terraform inicializado"
}

# Terraform plan
terraform_plan() {
    log_info "Generando plan de Terraform..."
    terraform plan -out=tfplan
    log_info "✓ Plan generado"
    
    read -p "¿Continuar con el despliegue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Despliegue cancelado por el usuario"
        exit 0
    fi
}

# Terraform apply
terraform_apply() {
    log_info "Aplicando configuración de Terraform..."
    terraform apply tfplan
    log_info "✓ Infraestructura desplegada"
    
    # Guardar outputs
    terraform output -json > outputs.json
    log_info "✓ Outputs guardados en outputs.json"
}

# Esperar a que la VM esté lista
wait_for_vm() {
    log_info "Esperando a que la VM esté lista..."
    sleep 30
    
    VM_IP=$(terraform output -raw mysql_private_ip)
    SSH_KEY=$(terraform output -raw ssh_private_key_path)
    
    log_info "Verificando conectividad SSH..."
    RETRIES=10
    while [ $RETRIES -gt 0 ]; do
        if ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=no azureuser@$VM_IP "echo 'SSH OK'" &> /dev/null; then
            log_info "✓ VM lista y accesible"
            return 0
        fi
        log_warn "Intentando conectar a VM... ($RETRIES intentos restantes)"
        RETRIES=$((RETRIES-1))
        sleep 10
    done
    
    log_error "No se pudo conectar a la VM"
    exit 1
}

# Configurar Ansible
configure_ansible() {
    log_info "Configurando Ansible..."
    
    VM_IP=$(terraform output -raw mysql_private_ip)
    
    # Crear inventory dinámico
    cat > ansible/inventory.ini << EOF
[mysql_vm]
mysql-vm-los5 ansible_host=$VM_IP ansible_user=azureuser

[mysql_vm:vars]
ansible_ssh_private_key_file=../ssh_keys/mysql_vm_key.pem
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    
    log_info "✓ Inventory de Ansible configurado"
}

# Ejecutar Ansible
run_ansible() {
    log_info "Ejecutando configuración de MySQL con Ansible..."
    
    # Exportar variables de entorno
    export MYSQL_ROOT_PASSWORD=$(grep mysql_root_password terraform.tfvars | cut -d'"' -f2)
    export MYSQL_DATABASE=$(grep mysql_database terraform.tfvars | cut -d'"' -f2)
    export MYSQL_USER=$(grep mysql_user terraform.tfvars | cut -d'"' -f2)
    export MYSQL_PASSWORD=$(grep mysql_password terraform.tfvars | cut -d'"' -f2 | tail -n1)
    
    cd ansible
    
    # Test de conectividad
    log_info "Verificando conectividad con Ansible..."
    if ! ansible mysql_vm -i inventory.ini -m ping; then
        log_error "No se pudo conectar a la VM con Ansible"
        exit 1
    fi
    
    # Ejecutar playbook
    log_info "Ejecutando playbook de configuración..."
    ansible-playbook -i inventory.ini mysql-config.yml
    
    cd ..
    log_info "✓ MySQL configurado correctamente"
}

# Mostrar información de despliegue
show_deployment_info() {
    log_info "========================================="
    log_info "DESPLIEGUE COMPLETADO EXITOSAMENTE"
    log_info "========================================="
    echo
    
    log_info "App Service URL:"
    terraform output app_service_url
    echo
    
    log_info "MySQL Private IP:"
    terraform output mysql_private_ip
    echo
    
    log_info "Para conectarte a MySQL vía SSH:"
    terraform output ssh_connection_command
    echo
    
    log_info "Siguiente paso:"
    log_info "  Despliega tu aplicación Node.js al App Service"
    log_info "  Ver README.md para más información"
}

# Función principal
main() {
    log_info "========================================="
    log_info "SCRIPT DE DESPLIEGUE AUTOMATIZADO"
    log_info "Azure Infrastructure - Los5"
    log_info "========================================="
    echo
    
    check_prerequisites
    check_azure_login
    check_tfvars
    get_public_ip
    create_directories
    terraform_init
    terraform_plan
    terraform_apply
    wait_for_vm
    configure_ansible
    run_ansible
    show_deployment_info
    
    log_info "========================================="
    log_info "¡PROCESO COMPLETADO!"
    log_info "========================================="
}

# Manejo de errores
trap 'log_error "Script interrumpido"; exit 1' INT TERM

# Ejecutar
main "$@"