# SIEM EKF

## Description

This project demonstrates how to build a **mini SIEM system** using **Elastic Stack** (Elasticsearch + Kibana) and **Filebeat** for log collection.
Everything runs in **Docker Compose** and includes a PowerShell script to simulate SSH logs in real time.

**Main components:**
- `Elasticsearch` → search and indexing engine.
- `Kibana` → dashboard and visualization interface.
- `Filebeat` → lightweight log collector agent.
- `simulate_errors_v1.sh` → PowerShell random log generator for SSH events.
- `simulate_errors_v2.sh` → PowerShell random log generator for SSH events.

## Structure
```
/siem-ekf/
├── docker-compose.yml
├── filebeat_tokenizer.yml
├── simulate_errors_v1.sh
├── simulate_errors_v2.sh
└── logs/
```

## Quick Start

### Start Elastic stack
Go to the project folder and start the containers:

```bash
docker compose up -d
```

Verify that everything is running:
```bash
docker ps
```

Log in to Kibana:
[http://localhost:5601](http://localhost:5601)



### Simulate SSH logs
Open your terminal and run:

```bash
# Run the log simulation script
bash ./simulate_errors_v1.sh

or

bash ./simulate_errors_v2.sh
```

The script will generate log files in the `logs/` folder, which Filebeat will read and send to Elasticsearch.

The data will be visible in Kibana under the `filebeat-*` index.

---

### Stop the Elastic stack
To stop the environment without removing containers:
```bash
docker compose stop
```

To restart:
```bash
docker compose start
```

To completely shut down and delete containers:
```bash
docker compose down
```

## Filebeat Indexes in Kibana

Once the logs are sent, open Kibana →
**Analytics → Discover → Create Data View**
and select the `filebeat-*` index.

From here, you can explore:
- suspicious users (`user.keyword`),
- source IP (`source.ip`),
- failed attempts, ports, timestamps, etc.