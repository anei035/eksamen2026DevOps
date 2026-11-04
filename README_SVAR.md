## Oppgave 1A — Container

Multi-stage `Dockerfile` ligger i roten av repoet. Første steg bygger applikasjonen med Maven og JDK 21, andre steg kjører kun JAR-filen på et JRE 21-image. Byggeverktøy og kildekode blir dermed ikke med i det endelige imaget.

Imaget publiseres til Docker Hub av pipelinen i 1B. For å starte en container som lytter på localhost:9999, kjør følgende kommando med egne AWS-nøkler:

```
docker run -p 9999:8080 -e AWS_ACCESS_KEY_ID=<access key> -e AWS_SECRET_ACCESS_KEY=<secret key> anei21638/wishifai:latest
```

Test:

```
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze
```
## Oppgave 1B — CI-pipeline

- Workflow-fil: [.github/workflows/build.yml](.github/workflows/build.yml)
- Grønn kjøring: https://github.com/anei035/eksamen2026DevOps/actions/runs/41339855160
- ECR: `244530008913.dkr.ecr.eu-west-1.amazonaws.com/kandidat42-wishifai`
- Docker Hub: `anei21638/wishifai`

Workflowen kjører kun ved push til `main`, og publiserer imaget til både ECR (brukes av ECS i oppgave 2) og Docker Hub.

**Tagging-strategi:** Hvert image tagges med kort commit-SHA (f.eks. `50d8f31`) og `latest`. Commit-SHA gjør det mulig å spore nøyaktig hvilken versjon av koden som kjører hvor, og å rulle tilbake til en tidligere versjon. `latest` peker alltid på siste bygg fra `main`, og gjør det enkelt å hente nyeste versjon.

**For sensor:** Legg inn følgende repository secrets i din fork (Settings → Secrets and variables → Actions):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKER_USERNAME`
- `DOCKER_TOKEN`

## Oppgave 2A — Infrastruktur for tjenesten

- Terraform-kode: [infra/](infra/)
- Offentlig URL: https://wi-ebffc86512ba4fba8b1c95659d4fd8ef.ecs.eu-west-1.on.aws

Test:

```
curl -F "image=@samples/sample_image.png" https://wi-ebffc86512ba4fba8b1c95659d4fd8ef.ecs.eu-west-1.on.aws/api/analyze
```

Terraform-koden oppretter en ECS Express-tjeneste, en S3-bucket for bilder og en task role (`wishifai-task-role-kandidat42`) som gir tjenesten tilgang til Rekognition, Bedrock og S3. Execution role og infrastructure role er de eksisterende rollene i kontoen.

Variabler: `region`, `kandidatnummer` og `image_tag`. URL-en eksponeres som output `service_url`. Miljøvariabelen `S3_BUCKET` settes automatisk fra bucket-ressursen i Terraform.

`container_port` er satt til 8080 og `health_check_path` til `/api/health`, siden standardverdiene (80 og `/`) ikke passer applikasjonen.

## Oppgave 2B — Remote state

State lagres i den delte S3-bucketen `pgr301-terraform-state` med nøkkel `wishifai/42/terraform.tfstate` (se [infra/backend.tf](infra/backend.tf)). Nøkkelen inneholder prosjektnavn og kandidatnummer, slik at den er unik og ikke overskriver andre kandidaters state i den delte bucketen. `use_lockfile = true` hindrer at to samtidige kjøringer endrer state samtidig.