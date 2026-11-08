# Besvarelse PGR301 – Kandidat 42

## Oppgave 1A

Dockerfilen ligger i roten av repoet og er en multi-stage build. Det første steget bygger applikasjonen med Maven og JDK 21, og det andre steget kjører bare JAR-filen på et JRE 21-image. Da blir ikke Maven, JDK og kildekoden med i det ferdige imaget.

Imaget blir publisert til Docker Hub av pipelinen i 1B. Containeren kan startes på localhost:9999 med denne kommandoen (bruk egne AWS-nøkler):

```
docker run -p 9999:8080 -e AWS_ACCESS_KEY_ID=<access key> -e AWS_SECRET_ACCESS_KEY=<secret key> anei21638/wishifai:latest
```

Og testes med:

```
curl -F "image=@samples/sample_image.png" http://localhost:9999/api/analyze
```

## Oppgave 1B

Workflowen ligger i .github/workflows/build.yml og kjører bare ved push til main. Den bygger imaget og pusher det både til ECR (som brukes av ECS i oppgave 2) og til Docker Hub.

Grønn kjøring: https://github.com/anei035/eksamen2026DevOps/actions/runs/41339855160

ECR-repo: 244530008913.dkr.ecr.eu-west-1.amazonaws.com/kandidat42-wishifai
Docker Hub: anei21638/wishifai

Jeg tagger hvert image med kort commit-SHA (f.eks. 50d8f31) og latest. Med commit-SHA kan man se nøyaktig hvilken versjon av koden som kjører hvor, og det er lett å rulle tilbake til en tidligere versjon. Latest peker alltid på siste bygg fra main, så det er enkelt å hente nyeste versjon.

For å kjøre workflowen i en fork må sensor legge inn disse repository secrets under Settings -> Secrets and variables -> Actions: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DOCKER_USERNAME og DOCKER_TOKEN.

## Oppgave 2A

Terraform-koden ligger i infra/. Den lager en ECS Express-tjeneste, en S3-bucket for bildene og en task role (wishifai-task-role-kandidat42) som gir tjenesten tilgang til Rekognition, Bedrock og S3. Execution role og infrastructure role er de eksisterende rollene i kontoen.

Offentlig URL: https://wi-ebffc86512ba4fba8b1c95659d4fd8ef.ecs.eu-west-1.on.aws

```
curl -F "image=@samples/sample_image.png" https://wi-ebffc86512ba4fba8b1c95659d4fd8ef.ecs.eu-west-1.on.aws/api/analyze
```

Jeg har variabler for region, kandidatnummer og image_tag, og URL-en kommer ut som output service_url. S3_BUCKET settes automatisk i Terraform ut fra bucketen som blir laget.

Jeg satte container_port til 8080 og health_check_path til /api/health, fordi standardverdiene (80 og /) ikke passer med applikasjonen.

## Oppgave 2B

State lagres i den delte bucketen pgr301-terraform-state med nøkkelen wishifai/42/terraform.tfstate (se infra/backend.tf). Nøkkelen har med prosjektnavn og kandidatnummer, så den er unik og ikke overskriver state til andre i klassen. Jeg bruker use_lockfile = true slik at to kjøringer ikke kan endre state samtidig.

## Oppgave 2C

Terraform-jobben ligger i samme workflow som i 1B, så workflowen har nå to jobber: build_docker_image bygger og pusher imaget, og terraform kjører terraform init, terraform fmt -check og terraform apply mot infra/. Terraform-jobben har needs: build_docker_image, så den starter først når imaget er pushet. Commit-SHA sendes inn som image_tag, slik at ECS deployer imaget som akkurat ble bygget. Pipelinen feiler hvis Terraform-koden ikke er riktig formatert.

Grønn kjøring: https://github.com/anei035/eksamen2026DevOps/actions/runs/41915763850

Terraform må kjøre etter container-bygget fordi ECS-tjenesten peker på et image med en bestemt tag. Hvis Terraform kjørte før eller samtidig, ville ikke imaget finnes i ECR ennå, og deployet ville feilet. Når den kjører etterpå, vet vi at imaget finnes, og hver commit til main blir deployet med akkurat den versjonen av koden.

## Oppgave 3A

Siden gründeren synes tjenesten er treg, måler jeg de to eksterne kallene hver for seg for å se hvor tiden blir av. I tillegg har jeg én business-metrikk. Alle metrikkene sendes til CloudWatch under namespace kandidat42.

rekognition_latency og bedrock_latency er Timere som måler hvor lang tid Rekognition og Bedrock bruker. En Timer gir antall kall, gjennomsnittstid og maks tid, så man ser ikke bare snittet, men også hvor trege de verste kallene er. Jeg har brukt @Timed på metodene i RekognitionService og BedrockService, med TimedAspect registrert i TimedConfig.

gift_suggestions er en Counter som teller antall gaveforslag som blir generert. Jeg valgte denne som business-metrikk fordi gaveforslagene er selve produktet Wishifai leverer. Den viser hvor mye tjenesten faktisk brukes og hvor mye verdi den gir brukerne, noe gründeren kan vise til overfor investorer. Hvis den plutselig stopper opp, vet vi at brukerne ikke får verdi lenger, selv om tjenesten teknisk sett svarer. Jeg brukte Counter fordi antallet bare kan øke.

Resultatet var at Bedrock-kallet i snitt tar rundt 14,5 sekunder, mens Rekognition tar rundt 1,1 sekunder. Bedrock står altså for omtrent 93 % av responstiden og er hovedgrunnen til at tjenesten er treg.