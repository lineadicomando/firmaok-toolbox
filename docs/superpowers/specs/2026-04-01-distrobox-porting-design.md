# Design: porting completo a distrobox

## Obiettivo

Effettuare un porting completo del progetto da comandi e nomenclatura legati a toolbox a comandi e nomenclatura legati a distrobox, mantenendo invariati i flussi operativi (`build`, `create`, `install`, `enter`, `reset`, `uninstall`) e il comportamento funzionale lato utente.

Vincolo esplicito: nessun riferimento residuo a toolbox nei file operativi e documentazione del progetto.

## Contesto attuale

Il repository usa oggi i comandi toolbox nei seguenti punti principali:

- `Makefile`: target `create`, `enter`, `install`
- `scripts/init.sh`: esecuzione script dentro container
- `scripts/reset.sh`: ricreazione container
- `container/init-firmaok.sh`: launcher desktop (`Exec=`)
- `README.md`: guida e prerequisiti

Il resto del flusso (build immagine via `podman build`, uninstall via podman + cleanup host) e' gia' compatibile con un passaggio a distrobox.

## Scelta progettuale

Approccio scelto: sostituzione diretta e completa (solo distrobox), senza modalita' ibride.

Ragioni:

- minimizza ambiguita' operative
- riduce rami condizionali e complessita' di manutenzione
- allinea comandi, variabili e documentazione ad un solo runtime

## Architettura delle modifiche

### 1) Makefile

- Rinominare variabile:
  - da `TOOLBOX`
  - a `DISTROBOX`
- Aggiornare target:
  - `create`: `podman container exists "$(DISTROBOX)" || distrobox create --name "$(DISTROBOX)" --image "$(IMAGE)"`
  - `enter`: `distrobox enter "$(DISTROBOX)"`
  - `install`: `bash scripts/init.sh "$(DISTROBOX)"`
  - `reset`: `bash scripts/reset.sh "$(DISTROBOX)" "$(IMAGE)"`
  - `uninstall`: `bash scripts/uninstall.sh "$(DISTROBOX)" "$(IMAGE)"`
- Aggiornare help testuale in italiano coerente con distrobox.

### 2) scripts/init.sh

- Rinominare variabile interna in `DISTROBOX_NAME`.
- Eseguire init nel container con:
  - `distrobox enter "${DISTROBOX_NAME}" -- env FIRMAOK_DISTROBOX_NAME="${DISTROBOX_NAME}" /usr/local/bin/init-firmaok.sh`
- Lasciare invariati refresh cache icone/desktop lato host.

### 3) scripts/reset.sh

- Rinominare variabile in `DISTROBOX_NAME`.
- Mantenere stop/rm container via podman.
- Ricreare con:
  - `distrobox create --name "${DISTROBOX_NAME}" --image "${IMAGE_NAME}"`

### 4) container/init-firmaok.sh

- Rinominare variabile ambiente da `FIRMAOK_TOOLBOX_NAME` a `FIRMAOK_DISTROBOX_NAME`.
- Aggiornare default nome container a `firmaok-distrobox`.
- Modificare desktop entry:
  - da `Exec=toolbox run -c ... firmaOK`
  - a `Exec=distrobox enter ... -- firmaOK`

### 5) README.md

- Aggiornare testo descrittivo da toolbox a distrobox.
- Aggiornare prerequisiti (`distrobox` al posto di `toolbox`).
- Aggiornare lista target e variabili (`DISTROBOX` al posto di `TOOLBOX`).
- Mantenere note legali e operative non correlate.

## Criteri di accettazione

- Nessun riferimento residuo a `toolbox` nei file:
  - `Makefile`
  - `scripts/init.sh`
  - `scripts/reset.sh`
  - `container/init-firmaok.sh`
  - `README.md`
- `make help` espone descrizioni coerenti con distrobox.
- `make create` crea il container distrobox se assente.
- `make enter` entra nel container distrobox.
- `make install` esegue correttamente init nel container distrobox.
- `~/.local/share/applications/firmaOk.desktop` contiene `Exec=distrobox enter ... -- firmaOK`.
- `make reset` ricrea correttamente il container distrobox.
- `make uninstall` conserva il comportamento esistente.

## Piano di verifica manuale

1. `make help`
2. `make create`
3. `make enter`
4. `make install`
5. Verifica launcher desktop (`Exec=`)
6. `make reset`
7. `make uninstall` con risposta `N`
8. `make uninstall` con risposta `s`

## Rischi e mitigazioni

- **Rischio:** differenze semantiche tra `toolbox run` e `distrobox enter --`.
  - **Mitigazione:** test esplicito del passaggio variabili ambiente e percorso script di init.
- **Rischio:** naming variabili incoerente dopo il porting.
  - **Mitigazione:** grep di validazione su `toolbox` nei file target.

## Scope e non-scope

In scope:

- solo porting operativo e documentale da toolbox a distrobox

Out of scope:

- nuove feature
- refactor non necessari
- supporto duale toolbox+distrobox
