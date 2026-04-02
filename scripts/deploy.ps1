# deploy.ps1 - Deployment script for Platform Landing Zone
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate", "format")]
    [string]$Action = "apply",
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Platform Landing Zone Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow

# Check prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    $azVersion = az version 2>$null
    if (-not $azVersion) {
        Write-Error "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    $tfVersion = terraform version 2>$null
    if (-not $tfVersion) {
        Write-Error "Terraform is not installed. Please install it first."
        exit 1
    }
    
    Write-Host "âœ“ Azure CLI and Terraform are installed" -ForegroundColor Green
}

# Login to Azure
function Connect-Azure {
    Write-Host "Checking Azure authentication..." -ForegroundColor Cyan
    
    $account = az account show 2>$null
    if (-not $account) {
        Write-Host "Please login to Azure..." -ForegroundColor Yellow
        az login
    }
    
    $account = az account show | ConvertFrom-Json
    Write-Host "âœ“ Logged in as: $($account.user.name)" -ForegroundColor Green
}

# Main execution
function Initialize-Terraform {
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    terraform init
}

function Format-Terraform {
    Write-Host "Formatting Terraform files..." -ForegroundColor Cyan
    terraform fmt -recursive
}

function Validate-Terraform {
    Write-Host "Validating Terraform configuration..." -ForegroundColor Cyan
    terraform validate
}

function Plan-Terraform {
    Write-Host "Generating Terraform plan..." -ForegroundColor Cyan
    terraform plan -out=platform-lz.tfplan
}

function Apply-Terraform {
    Write-Host "Applying Terraform configuration..." -ForegroundColor Cyan
    
    if ($AutoApprove) {
        terraform apply -auto-approve platform-lz.tfplan
    } else {
        Write-Host "Review the plan above. Do you want to apply? (yes/no)" -ForegroundColor Yellow
        $confirmation = Read-Host
        if ($confirmation -eq "yes") {
            terraform apply platform-lz.tfplan
        } else {
            Write-Host "Apply cancelled." -ForegroundColor Red
            exit 0
        }
    }
}

function Destroy-Terraform {
    Write-Host "WARNING: This will destroy all resources!" -ForegroundColor Red
    
    if (-not $AutoApprove) {
        Write-Host "Type 'yes' to confirm destruction: " -ForegroundColor Yellow
        $confirmation = Read-Host
        if ($confirmation -ne "yes") {
            Write-Host "Destroy cancelled." -ForegroundColor Red
            exit 0
        }
    }
    
    terraform destroy -auto-approve
}

# Run tests
Test-Prerequisites
Connect-Azure

# Execute action
switch ($Action) {
    "init" { Initialize-Terraform }
    "format" { Format-Terraform }
    "validate" { Validate-Terraform }
    "plan" { 
        Initialize-Terraform
        Plan-Terraform
    }
    "apply" {
        Initialize-Terraform
        Plan-Terraform
        Apply-Terraform
    }
    "destroy" {
        Initialize-Terraform
        Destroy-Terraform
    }
    default {
        Write-Host "Invalid action. Use: init, plan, apply, destroy, validate, format" -ForegroundColor Red
    }
}

Write-Host "Deployment script completed!" -ForegroundColor Green
