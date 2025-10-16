# Mini SIEM con Elastic Stack, Kibana e Filebeat

> IT *Progetto didattico per la simulazione di log e visualizzazione eventi di sicurezza con Elastic Stack in Docker.*  
> EN *Educational project to simulate system logs and visualize security events using Elastic Stack in Docker.*

---

## Playlist YouTube
🎥 Segui la serie completa su YouTube → [**Archety.dev - Progetto SIEM con ELK**](https://www.youtube.com/playlist?list=PLoZNHBEyxFQG4JR0-EDjUsY9G8dfS2idl)  

---

## 🇮🇹 Descrizione (IT)

Questo progetto mostra come creare un **mini sistema SIEM** utilizzando **Elastic Stack** (Elasticsearch + Kibana) e **Filebeat** per la raccolta dei log.  
Il tutto è orchestrato con **Docker Compose** e include uno script PowerShell che genera log simulati SSH in tempo reale.

**Componenti principali:**
- `Elasticsearch` → motore di ricerca e indicizzazione dei log.  
- `Kibana` → dashboard e interfaccia di visualizzazione.  
- `Filebeat` → agente di raccolta log locale.  
- `simula_errori_v2.ps1` → generatore casuale di log SSH per test e demo.

---

## 🇬🇧 Description (EN)

This project demonstrates how to build a **mini SIEM system** using **Elastic Stack** (Elasticsearch + Kibana) and **Filebeat** for log collection.  
Everything runs in **Docker Compose** and includes a PowerShell script to simulate SSH logs in real time.

**Main components:**
- `Elasticsearch` → search and indexing engine.  
- `Kibana` → dashboard and visualization interface.  
- `Filebeat` → lightweight log collector agent.  
- `simula_errori_v2.ps1` → PowerShell random log generator for SSH events.

---

## ⚙️ Requisiti / Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop)  
- PowerShell (Windows o PowerShell 7+ su Linux/Mac)
- Struttura consigliata:
  ```
  /progetto-siem/
  ├── docker-compose.yml
  ├── filebeat.yml
  ├── simula_errori_v2.ps1
  └── logs/
  ```

---

## Avvio rapido (Quick Start)

### Avvia lo stack Elastic
Posizionati nella cartella del progetto e avvia i container:

```bash
docker compose up -d
```

Verifica che tutto sia in esecuzione:
```bash
docker ps
```

Accedi a Kibana:
👉 [http://localhost:5601](http://localhost:5601)

---

### Simula log SSH (PowerShell)
Apri una finestra **PowerShell** e lancia:

```powershell
# Esegui lo script di simulazione log
powershell -ExecutionPolicy Bypass -File .\simula_errori_v2.ps1
```

Lo script genererà file di log nella cartella `logs/`, che Filebeat leggerà e invierà a Elasticsearch.  
I dati saranno visibili in Kibana sotto l’indice `filebeat-*`.

---

### Arresta lo stack Elastic
Per fermare l’ambiente senza rimuovere i container:
```bash
docker compose stop
```

Per riavviare:
```bash
docker compose start
```

Per spegnere completamente ed eliminare i container:
```bash
docker compose down
```

---

## Indici Filebeat in Kibana

Una volta che i log vengono inviati, apri Kibana →  
**Analytics → Discover → Create Data View**  
e seleziona l’indice `filebeat-*`.

Da qui potrai esplorare:
- utenti sospetti (`user.keyword`),  
- IP di origine (`source.ip`),  
- tentativi falliti, porte, timestamp, ecc.

---

## Architettura (Architecture Overview)

```
[ simula_errori_v2.ps1 ] 
          ↓
      [ logs/*.log ]
          ↓
      [ Filebeat ]
          ↓
    [ Elasticsearch ]
          ↓
        [ Kibana ]
```

---

## Comandi utili (Useful Docker commands)

| Azione | Comando |
|--------|----------|
| Avvia stack | `docker compose up -d` |
| Ferma stack | `docker compose stop` |
| Riavvia stack | `docker compose start` |
| Arresta ed elimina container | `docker compose down` |
| Mostra log container | `docker compose logs -f` |
| Lista container attivi | `docker ps` |

---

## Crediti / Credits

👨‍💻 **Autore:** [Giovanni Pace](https://github.com/johnnypax)  
📺 **Canale YouTube:** [Archety.dev](https://www.youtube.com/@ArchetyDev)  
📧 Contatti e aggiornamenti: *info@archety.dev*  

---

## Licenza / License

MIT License © 2025 [Giovanni Pace](https://github.com/johnnypax)
