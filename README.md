# AuktionsHuset Bicep Deployment

Dette repository indeholder Bicep-scripts til deployment af 5 microservices til Azure. Følgende guide beskriver, hvordan du opsætter og administrerer dine Azure-ressourcer ved hjælp af disse scripts.

## Forudsætninger

Før du kan bruge disse scripts, skal du have følgende:
- En Azure-konto
- Azure CLI installeret på din lokale maskine
- Bash shell (for at køre shell scripts)

## Opsætning

1. Clone dette repository:
    ```sh
    git clone https://github.com/Hablas-Si/Deployment.git
    ```

2. Gå ind i underfolder:
    ```sh
    cd Bicep-scripts
    ```
3. Kør script  az-commands.sh


## Opdatering af containers

Hvis du har brug for at opdatere dine containers, kan du bruge følgende kommando:

```sh
az deployment group create --resource-group $ResourceGroup --template-file Bicep-scripts/auctionsGO.bicep --debug
 ```


## Bemærk
Hvis du skal allokere mere eller mindre CPU eller hukommelse til en service, skal du slette containergruppen på azure portalen og derefter udføre kommandoerne igen:

```sh
az deployment group create --resource-group $ResourceGroup --template-file Bicep-scripts/auctionsGO.bicep --debug
 ```

## Administration af ressourcer
For at spare på din Azure-konto kan du bruge shutdown.sh og startup.sh scripts til at slukke og starte alle ressourcer i din ressourcegruppe. 

Startup Script
Kør startup.sh for at starte alle ressourcer i ressourcegruppen:
```sh
./startup.sh
 ```

Shutdown Script
Kør shutdown.sh for at slukke alle ressourcer i ressourcegruppen:
```sh
./shutdown.sh
 ```


