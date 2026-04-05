# firmaok-toolbox

Setup minimale per costruire un'immagine Toolbox con firmaOK e inizializzare integrazione desktop lato host.

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Versione corrente: `v0.1.0`

## Perche' esiste questo progetto

Questo progetto nasce per aggirare un comportamento anomalo riscontrato con firmaOK sulle versioni recenti di Fedora: l'applicazione si avvia, ma non compare la schermata di login per la funzione **Firma Digitale Remota**.

Nel sito ufficiale da cui si scarica l'app (`https://www.poste.it/firma-digitale-remota`) viene indicato esplicitamente come sistema compatibile Linux: **Ubuntu (ultima LTS)**. L'obiettivo di questo repository e' quindi offrire un ambiente compatibile e ripetibile tramite Toolbox.

Il progetto e' focalizzato sulla **Firma Digitale Remota** e non e' predisposto ne' testato per la funzione **Firma con dispositivo**.

## Guida operativa

### 1 - Installare i requisiti:

#### Fedora/RedHat e derivate

```bash
sudo dnf install -y podman toolbox git make
```

#### Arch Linux e derivate

```bash
sudo pacman -S podman toolbox git make
```

#### Debian

```bash
sudo apt update
sudo apt install podman-toolbox git make
```

### 2 - Clonare il repository:

```bash
git clone https://github.com/lineadicomando/firmaok-toolbox.git
cd firmaok-toolbox
```

### 3 - Avviare il setup completo al primo utilizzo:

```bash
make setup
```

Il setup genera in `~/.local/share/applications` il Desktop Entry per lanciare l'applicazione, tuttavia è possibile avviare firmaOK da console con:

```bash
make run
```

## Note legali

Questo progetto non distribuisce `firmaOK` e non include componenti proprietari di terze parti oltre a quelli eventualmente necessari per l'integrazione o l'automazione locale. Il repository fornisce solo un wrapper/toolbox per semplificare l'esecuzione e la configurazione dell'ambiente.

Tutti i marchi, i nomi commerciali, i prodotti e i servizi di terze parti citati nel progetto appartengono ai rispettivi titolari. Ogni riferimento a tali elementi e' da intendersi esclusivamente a fini descrittivi o di compatibilita', e rimanda alle relative condizioni d'uso, licenze e termini applicabili.

Questo progetto non e' affiliato, sponsorizzato o approvato dai titolari dei marchi o dei prodotti citati, salvo diversa indicazione esplicita.

## Struttura

- `container/Containerfile`: definizione immagine
- `container/init-firmaok.sh`: installazione idempotente di firmaOK dentro il container
- `scripts/container-backend.sh`: utilita' per gestione backend (`toolbox`/`distrobox`)
- `scripts/init.sh`: installazione/configurazione completa (run script nel container + refresh cache desktop/icona sul host)
- `scripts/reset.sh`: stop/rimozione container e recreate
- `scripts/uninstall.sh`: rimozione artefatti locali/container/immagine
- `Makefile`: comandi operativi

## Target principali

- `make setup`: primo avvio completo (`build install`; `install` crea il toolbox se serve)
- `make build`: build immagine (`$(IMAGE)`)
- `make create`: crea toolbox (`$(TOOLBOX)`) se non esiste
- `make install`: installa/configura firmaOK nel toolbox
- `make run`: avvia firmaOK da console
- `make enter`: entra nel toolbox
- `make reset`: stop + remove + recreate toolbox
- `make uninstall`: richiede conferma e rimuove container, immagine e file installati in locale

Nota di sicurezza: `make uninstall` e' un'operazione distruttiva e non reversibile. Rimuove `~/.local/opt/firmaOK` e le impostazioni/personalizzazioni locali; e' comunque possibile reinstallare l'ambiente con `make setup`.

Eseguendo `make` senza argomenti si mostra l'help generato dai commenti `##` nel `Makefile`, in italiano.

## Variabili Make

- `IMAGE` (default `localhost/firmaok-toolbox:latest`)
- `TOOLBOX` (default `firmaok-toolbox`)
- `CONTAINERFILE` (default `container/Containerfile`)

## Backend container

Il backend predefinito e' Toolbox.
In alternativa puoi usare Distrobox impostando `CONTAINER_BACKEND=distrobox`.**

Puoi configurare backend, nome container e immagine anche via `.env` nella root del progetto:

```bash
CONTAINER_BACKEND=toolbox
CONTAINER_NAME=firmaok-toolbox
IMAGE=localhost/firmaok-toolbox:latest
```

**Attenzione: il supporto a distrobox è sperimentale e non completamente testato.

Nota: il ciclo di vita del container usa esclusivamente Podman.
