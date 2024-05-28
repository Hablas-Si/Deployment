#!/bin/bash

az login

# opret ressourcegruppe
ResourceGroup=AuktionsHusetRG
az group create --name $ResourceGroup --location northeurope

# deploy bicep fil
az deployment group create --resource-group $ResourceGroup --template-file auctionsGO.bicep --verbose

# verificer ressourcer i ressourcegruppen
az resource list --resource-group $ResourceGroup
