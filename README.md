# firmaok-toolbox

Setup minimale per costruire un'immagine Toolbox con firmaOK e inizializzare integrazione desktop lato host.

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Versione corrente: `v0.1.0`

## Perche' esiste questo progetto

Questo progetto nasce per aggirare un comportamento anomalo riscontrato con firmaOK sulle versioni recenti di Fedora: l'applicazione si avvia, ma non compare la schermata di login per la funzione **Firma Digitale Remota**.

Nel sito ufficiale da cui si scarica l'app (`https://www.poste.it/firma-digitale-remota`) viene indicato esplicitamente come sistema compatibile Linux: **Ubuntu (ultima LTS)**. L'obiettivo di questo repository e' quindi offrire un ambiente compatibile e ripetibile tramite Toolbox.

Il progetto e' focalizzato sulla **Firma Digitale Remota** e non e' predisposto ne' testato per la funzione **Firma con dispositivo**.

## Note legali

Questo progetto non distribuisce `firmaOK` e non include componenti proprietari di terze parti oltre a quelli eventualmente necessari per l'integrazione o l'automazione locale. Il repository fornisce solo un wrapper/toolbox per semplificare l'esecuzione e la configurazione dell'ambiente.

Tutti i marchi, i nomi commerciali, i prodotti e i servizi di terze parti citati nel progetto appartengono ai rispettivi titolari. Ogni riferimento a tali elementi e' da intendersi esclusivamente a fini descrittivi o di compatibilita', e rimanda alle relative condizioni d'uso, licenze e termini applicabili.

Questo progetto non e' affiliato, sponsorizzato o approvato dai titolari dei marchi o dei prodotti citati, salvo diversa indicazione esplicita.

## Struttura

- `container/Containerfile`: definizione immagine
- `container/init-firmaok.sh`: installazione idempotente di firmaOK dentro il container
- `scripts/init.sh`: installazione/configurazione completa (run script nel container + refresh cache desktop/icona sul host)
- `scripts/reset.sh`: stop/rimozione container e recreate
- `Makefile`: comandi operativi

## Debug

Per diagnosticare il comportamento del wrapper `xdg-open`, imposta `FIRMAOK_WRAPPER_DEBUG=1` prima di aprire un file o una cartella. In quel modo il wrapper stampa su `stderr` il flusso di esecuzione, il target risolto e il MIME type rilevato.

## Target principali

- `make setup`: primo avvio completo (`build install`; `install` crea il toolbox se serve)
- `make build`: build immagine (`$(IMAGE)`)
- `make create`: crea toolbox (`$(TOOLBOX)`) se non esiste
- `make install`: installa/configura firmaOK nel toolbox
- `make enter`: entra nel toolbox
- `make reset`: stop + remove + recreate toolbox
- `make uninstall`: richiede conferma e rimuove container, immagine e file installati in locale

Nota di sicurezza: `make uninstall` e' un'operazione distruttiva e non reversibile. Rimuove `~/.local/opt/firmaOK` e le impostazioni/personalizzazioni locali; e' comunque possibile reinstallare l'ambiente con `make setup`.

Eseguendo `make` senza argomenti si mostra l'help generato dai commenti `##` nel `Makefile`, in italiano.

## Variabili Make

- `IMAGE` (default `localhost/firmaok-toolbox:latest`)
- `TOOLBOX` (default `firmaok-toolbox`)
- `CONTAINERFILE` (default `container/Containerfile`)

## Guida operativa (Fedora)

1) Installare i requisiti (`toolbox`, `git`, `make`):

```bash
sudo dnf install -y toolbox git make
```

2) Clonare il repository:

```bash
git clone https://github.com/lineadicomando/firmaok-toolbox.git
cd firmaok-toolbox
```

3) Avviare il setup completo al primo utilizzo:

```bash
make setup
```

Per gli avvii successivi, `make install` riesegue la parte di installazione/configurazione (e prepara il toolbox se necessario), mentre `make build` e `make create` restano disponibili per aggiornare immagine e toolbox.
