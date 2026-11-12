# TD Cloud & Cybersécurité — Terraform, Azure Function, Azure SQL

Ce README explique **tout le TD de A à Z** : ce qu'on a construit, comment, et surtout **pourquoi**. Chaque partie se termine par les questions que le prof peut poser, avec une réponse courte.

Documents liés :
- [Cloud-Exercise-Terraform-Windows11.md](Cloud-Exercise-Terraform-Windows11.md) : le sujet du prof
- [EXPLAINED-SIMPLY.md](EXPLAINED-SIMPLY.md) : la version très simple
- [TESTS.md](TESTS.md) : les tests à lancer et comment
- [Phase2-Notes.md](Phase2-Notes.md) : notes techniques détaillées et preuves
- [NEXT-STEPS.md](NEXT-STEPS.md) : ce qu'il reste à faire

---

## Sommaire

1. [Le but du TD en une phrase](#1-le-but-du-td-en-une-phrase)
2. [L'architecture](#2-larchitecture)
3. [Vocabulaire indispensable](#3-vocabulaire-indispensable)
4. [Les outils](#4-les-outils)
5. [Le state Terraform distant](#5-le-state-terraform-distant-section-2-du-td)
6. [Le code Terraform fichier par fichier](#6-le-code-terraform-fichier-par-fichier)
7. [Le code Python](#7-le-code-python)
8. [Phase 1 — Construire et tester](#8-phase-1--construire-et-tester)
9. [Phase 2 — Sécuriser](#9-phase-2--sécuriser-hardening)
10. [Ce qu'on a découvert pendant le TD](#10-ce-quon-a-découvert-pendant-le-td)
11. [Monitoring](#11-monitoring-comme-contrôle-de-sécurité-66)
12. [Nettoyage](#12-nettoyage-section-7)
13. [Questions probables du prof](#13-questions-probables-du-prof)

---

## 1. Le but du TD en une phrase

Construire **avec Terraform** une petite API dans le cloud Azure (une *Function* en Python qui compte les appels par nom dans une base SQL), puis la **sécuriser étape par étape** (authentification, validation, secrets, droits minimum, réseau) et **observer** ce qui se passe grâce aux logs.

Exemple : on envoie `{"name": "Alice"}` → l'API répond `hello Alice this is your 17th call`.

Le TD a deux phases :
- **Phase 1** : faire marcher l'application (version volontairement **pas sécurisée**).
- **Phase 2** : la durcir (*hardening*) contrôle par contrôle, en re-testant à chaque fois.

---

## 2. L'architecture

```
   Client (curl / Postman / objet connecté)
        │  HTTPS + clé x-functions-key
        ▼
 ┌──────────────────────────────┐        ┌──────────────────────┐
 │ Function App (Python 3.11)   │───────▶│ Key Vault            │
 │ plan Consumption Linux (Y1)  │  lit   │ 2 secrets :          │
 │  POST /api/http_trigger      │ secrets│  - conn. "editor"    │
 │  GET  /api/names             │        │  - conn. "reader"    │
 │ identité managée (MI)        │        └──────────────────────┘
 └──────────────┬───────────────┘
                │ TLS (Encrypt=yes), port 1433
                ▼
 ┌──────────────────────────────┐
 │ Azure SQL (serverless)       │
 │ base NameCounterDB           │
 │ table dbo.Names(name, count) │
 │ pare-feu SQL                 │
 └──────────────────────────────┘

 Application Insights + Log Analytics : reçoivent les logs de la Function
 Storage account (stfunc...) : stockage technique obligatoire de la Function
 Storage account (tfstatergid) : le "state" Terraform (séparé, créé à la main)
```

Ressources réellement créées (groupe `rg-namecounter-lab-8cd658`, région Germany West Central) :

| Ressource | Nom | Rôle |
|---|---|---|
| Resource group | `rg-namecounter-lab-8cd658` | Le "dossier" qui contient tout |
| Function App | `func-namecounter-lab-8cd658` | Le code Python (l'API) |
| App Service plan | `asp-namecounter-lab` (Y1) | L'hébergement serverless |
| Storage account | `stfunc8cd658` | Stockage interne de la Function |
| SQL server + DB | `sql-namecounter-lab-8cd658` / `NameCounterDB` | La base de données |
| Key Vault | `kv-nc-8cd658` | Le coffre-fort des secrets |
| Application Insights | `appi-namecounter-lab-8cd658` | Les logs / la télémétrie |
| Log Analytics | `log-namecounter-lab-8cd658` | L'entrepôt où sont stockés les logs |
| Storage (state) | `tfstatergid` dans `rg-tfstate-prod` | Le fichier d'état Terraform |

Le suffixe `8cd658` est généré par `random_string` : il rend les noms **uniques dans tout Azure** (obligatoire pour SQL, Storage, Key Vault, Function).

---

## 3. Vocabulaire indispensable

| Mot | Explication simple |
|---|---|
| **Cloud / Azure** | Des ordinateurs de Microsoft qu'on loue à la demande |
| **IaC (Infrastructure as Code)** | Décrire l'infrastructure dans des fichiers texte au lieu de cliquer. Reproductible, versionné dans Git, relisible |
| **Terraform** | L'outil IaC utilisé. On décrit *l'état voulu*, Terraform calcule et applique la différence |
| **Provider** | Le plugin Terraform qui parle à un cloud (`azurerm` pour Azure) |
| **State** | Le fichier où Terraform note ce qu'il a créé. Il contient des **secrets en clair** |
| **Serverless** | On ne gère aucun serveur : Azure démarre le code quand une requête arrive et facture à l'usage |
| **Azure Function** | Un morceau de code lancé par un déclencheur (ici une requête HTTP) |
| **Plan Y1 (Consumption)** | L'offre serverless la moins chère. Limite : pas de réseau privé (VNet) |
| **Azure SQL serverless** | Base SQL qui **se met en pause** après 60 min sans usage (économie) |
| **Managed Identity (MI)** | Une identité donnée par Azure à la Function, sans mot de passe, pour accéder à d'autres services |
| **RBAC** | Contrôle d'accès par rôles (ex. "Key Vault Secrets User" = peut lire les secrets) |
| **Key Vault** | Coffre-fort Azure pour mots de passe, clés, certificats |
| **Application Insights** | Service qui collecte requêtes, erreurs, logs de l'application |
| **KQL** | Le langage de requête des logs (`requests | where ...`) |
| **Authentification** | Prouver **qui** on est (la clé de fonction) |
| **Autorisation** | Ce qu'on a **le droit** de faire (lecture seule, écriture...) |
| **Chiffrement (encryption)** | Rendre les données illisibles pendant le transport : **HTTPS / TLS** |
| **Moindre privilège** | Donner uniquement les droits strictement nécessaires |
| **Défense en profondeur** | Empiler plusieurs protections indépendantes : si une tombe, les autres tiennent |

Codes HTTP vus pendant le TD : **200** OK · **400** requête invalide · **401** non authentifié · **500** erreur serveur.

---

## 4. Les outils

Installés avec Chocolatey (section 1 du TD) :

| Outil | Sert à |
|---|---|
| `az` (Azure CLI) | Se connecter à Azure (`az login`), lire les ressources, les clés |
| `terraform` | Créer / modifier / détruire l'infrastructure |
| `func` (Azure Functions Core Tools) | Lancer la Function en local et la publier dans Azure |
| Python 3.11 + venv | Exécuter le code localement |
| ODBC Driver 18 | Pilote pour que Python (`pyodbc`) parle à SQL Server |
| Azurite | Émulateur local du stockage Azure (pour lancer la Function en local) |
| curl / Postman | Envoyer des requêtes HTTP de test |

Cycle Terraform à connaître par cœur :

```powershell
terraform init                 # télécharge les providers, connecte le backend (state)
terraform fmt                  # formate le code
terraform validate             # vérifie la syntaxe
terraform plan -out=tfplan     # calcule ce qui va changer (ne modifie rien)
terraform apply tfplan         # applique exactement ce plan
terraform output               # affiche les sorties (noms des ressources)
terraform destroy              # supprime tout
```

**Pourquoi `plan -out` puis `apply tfplan` ?** On applique **exactement** ce qu'on a relu. Sans fichier de plan, `apply` recalcule et pourrait faire autre chose si Azure a changé entre-temps.

---

## 5. Le state Terraform distant (section 2 du TD)

Terraform garde un fichier **state** qui fait le lien entre le code et les ressources réelles.

On l'a mis dans un **Storage Account Azure** (`tfstatergid`, conteneur `tfstate`), créé **à la main** avec `az` avant tout le reste, dans un groupe séparé `rg-tfstate-prod`.

Pourquoi :
- **Il contient des secrets en clair** (mots de passe SQL, chaînes de connexion). Il ne doit **jamais** être dans Git ni sur un PC sans protection. → `*.tfstate` est dans `.gitignore`.
- **Verrouillage (lock)** : deux personnes ne peuvent pas modifier en même temps. Pendant le TD, un `plan` interrompu a laissé un verrou ; on le libère avec `terraform force-unlock <id>`.
- **Accès par Entra ID** (`use_azuread_auth = true`) : on se connecte avec son identité `az login`, pas avec une clé de stockage.
- Groupe séparé : `terraform destroy` du projet ne supprime pas le state.

Paramètres sécurité du compte de stockage : `--min-tls-version TLS1_2` et `--allow-blob-public-access false`.

---

## 6. Le code Terraform fichier par fichier

| Fichier | Contenu |
|---|---|
| `versions.tf` | Version de Terraform, providers (`azurerm ~> 5.5`, `random`), **backend** (où est le state) |
| `variables.tf` | Les paramètres : région, environnement, IP du PC, mots de passe (marqués `sensitive`), etc. Avec des `validation` (ex. format de la région) |
| `terraform.tfvars` | Les **valeurs** des variables, dont les mots de passe → **ignoré par Git** |
| `main.tf` | Suffixe aléatoire + resource group avec des **tags** (Project, Environment, ManagedBy) |
| `monitoring.tf` | Log Analytics + Application Insights. Créés **dès le premier apply** : sur Y1 Linux, c'est le **seul moyen de voir les logs** |
| `functions.tf` | Storage de la Function, plan Y1, Function App Linux Python 3.11, `https_only = true`, identité managée, app settings |
| `sql.tf` | Serveur SQL (`minimum_tls_version = 1.2`), base serverless, règles de pare-feu |
| `keyvault.tf` | Key Vault (RBAC), rôles, 2 secrets (chaînes de connexion editor/reader) |
| `outputs.tf` | Noms utiles affichés après apply (`function_app_name`, etc.) |
| `network.tf` | Vide : prévu pour le niveau 2 de la 6.5 (VNet, private endpoint) |

Bonnes pratiques visibles dans le code :
- Variables `sensitive = true` → Terraform n'affiche pas les mots de passe à l'écran (mais ils restent dans le state).
- Tags sur toutes les ressources → savoir qui a créé quoi et pourquoi (coût, inventaire).
- `depends_on` sur les secrets Key Vault → la création du rôle doit avoir lieu **avant** l'écriture du secret (Terraform ne voit pas cette dépendance tout seul).
- `lifecycle { ignore_changes = [...] }` → ignorer un tag qu'Azure ajoute tout seul, pour que `plan` reste propre.
- `moved { }` → renommer une ressource dans le code sans la détruire/recréer.

---

## 7. Le code Python

`src/function_app.py` (modèle de programmation Python **v2** : les routes sont déclarées avec des décorateurs `@app.route`).

| Route | Méthode | Rôle | Login SQL utilisé |
|---|---|---|---|
| `/api/http_trigger` | POST | Lit `{"name": ...}`, ajoute 1 au compteur, répond `hello <name> this is your Nth call` | `app_editor_user` (lecture + écriture) |
| `/api/names` | GET | Renvoie la liste des noms et compteurs en JSON | `app_reader_user` (lecture seule) |

Points de sécurité dans le code :
- `AuthLevel.FUNCTION` → il faut la clé (6.1).
- `validate_name()` dans `src/sanitize.py` → liste blanche : lettres, chiffres, espace, tiret, 1 à 100 caractères (6.2).
- **Requêtes paramétrées** `cursor.execute("... WHERE name = ?", (name,))` → protège contre l'injection SQL.
- Les erreurs détaillées vont dans les **logs** (`logger.exception`) ; l'utilisateur reçoit seulement `{"error": "Internal error."}` → on ne divulgue pas d'informations internes.
- La chaîne de connexion vient d'une **variable d'environnement** (`SQL_CONNECTION_STRING`), jamais écrite dans le code.

Note : la collation SQL par défaut ignore la casse, donc `alice` et `Alice` sont **la même ligne**.

---

## 8. Phase 1 — Construire et tester

1. `terraform apply` crée toute l'infrastructure.
2. On crée la table `dbo.Names` avec `sqlcmd` depuis le PC (autorisé par la règle de pare-feu "IP du PC").
3. On lance la Function **en local** (`func start` + Azurite) contre la vraie base, avec la chaîne de connexion dans `local.settings.json` (ignoré par Git).
4. On publie : `func azure functionapp publish <nom>` (build distant Oryx).
5. On teste avec curl et Postman.

État **volontairement non sécurisé** à la fin de la phase 1 :
- API **anonyme** (n'importe qui peut l'appeler) ;
- mot de passe **admin** SQL en clair dans les app settings ;
- aucune validation du nom ;
- règle de pare-feu `0.0.0.0` (« autoriser les services Azure »).

C'est le point de départ de la phase 2.

---

## 9. Phase 2 — Sécuriser (hardening)

Principe : **un contrôle à la fois**, puis re-tester, puis vérifier dans Application Insights que le refus apparaît comme un 4xx attendu et pas comme une exception.

### 6.1 Authentification par clé

- **Fait :** `AuthLevel.ANONYMOUS` → `AuthLevel.FUNCTION`, republication.
- **Effet :** sans en-tête `x-functions-key` → **401**, avec la clé → **200**.
- **Testé :** oui (voir [TESTS.md](TESTS.md)).
- Le 401 est renvoyé par **l'hôte Azure Functions avant** que le code Python ne s'exécute.

**Limite :** une seule clé **partagée** par tous les clients. Si elle fuit, tout le monde peut appeler ; impossible de savoir quel appareil appelle ou d'en révoquer un seul. Mieux : une identité **par appareil** (Entra ID / OAuth, certificats clients, API Management avec une clé par abonné).

### 6.2 Validation des entrées

- **Fait :** `validate_name()` (expression régulière en liste blanche) appelée **avant** la base. Erreur → **400**.
- **Testé :** `{"name": "x'; DROP TABLE dbo.Names;--"}` → **400** `name: 1-100 characters...`.

**Pourquoi ça échoue sans danger :** deux couches.
1. La validation refuse `'` et `;` → la requête n'atteint jamais la base.
2. Même sans validation, la **requête paramétrée** (`?`) envoie le nom comme une **donnée**, jamais comme du code SQL → l'injection est impossible.

La validation ajoute aussi une limite de taille et de format (on ne stocke pas n'importe quoi).

### 6.3 Secrets dans Key Vault + identité managée

- **Fait :** les chaînes de connexion sont des **secrets Key Vault**. Dans la Function, l'app setting contient seulement une **référence** :
  `@Microsoft.KeyVault(SecretUri=...)`.
- La Function a une **identité managée** avec le rôle **Key Vault Secrets User** (lecture seule). Nous (le déployeur) avons **Key Vault Secrets Officer** (écriture).
- **Vérifié :** les deux références sont **Resolved** (Portail → Function → Environment variables).
- `versionless_id` → si on change le secret, la Function prend automatiquement la nouvelle version.

**Esprit critique :** le mot de passe a été **déplacé, pas supprimé**. Il est encore dans `terraform.tfvars` et dans le **state**. La vraie solution est **sans mot de passe** : authentification **Microsoft Entra** sur Azure SQL, l'identité managée de la Function créée comme utilisateur SQL (`CREATE USER [func-...] FROM EXTERNAL PROVIDER`), et une chaîne de connexion avec `Authentication=ActiveDirectoryMsi`. Plus aucun secret à voler ni à faire tourner.

### 6.4 Rôles SQL à moindre privilège

```sql
CREATE ROLE name_reader;  GRANT SELECT ON dbo.Names TO name_reader;
CREATE ROLE name_editor;  GRANT SELECT, INSERT, UPDATE ON dbo.Names TO name_editor;
CREATE USER app_reader_user WITH PASSWORD = '...';  ALTER ROLE name_reader ADD MEMBER app_reader_user;
CREATE USER app_editor_user WITH PASSWORD = '...';  ALTER ROLE name_editor ADD MEMBER app_editor_user;
```

- **Fait :** 2 secrets Key Vault (`SqlConnStringEditor`, `SqlConnStringReader`). POST utilise *editor*, le nouveau GET `/api/names` utilise *reader*.
- **Testé :** POST → 200 (écrit), GET → 200 (lit).
- Test demandé par le sujet : pointer POST sur le login *reader* → erreur `The UPDATE permission was denied` dans la table `exceptions`.

**Pourquoi 2 rôles étroits > 1 compte `db_owner` :** si le GET est compromis, l'attaquant peut seulement **lire** une table. Avec `db_owner`, il pourrait tout supprimer (`DROP`), créer des comptes, lire d'autres tables. Les utilisateurs sont aussi **contenus** dans la base (pas des logins serveur) et n'ont pas `DELETE` : on limite le **rayon d'explosion** (*blast radius*).

### 6.5 Segmentation réseau

**Principe :** limiter **qui peut joindre** un composant, indépendamment de qui peut s'y authentifier. Si un mot de passe fuit, l'attaquant a encore besoin d'un chemin réseau.

**6.5.1 Carte d'exposition** (brouillon dans [Phase2-Notes.md](Phase2-Notes.md) §6) : Function en entrée = tout Internet (obligatoire), SQL = services Azure + IP du PC, Key Vault / Storage = Internet protégé par RBAC ou clés.

**Contrainte clé :** le plan **Y1 ne supporte ni l'intégration VNet sortante ni les private endpoints**. Une base accessible uniquement en privé est donc **inutilisable** depuis une Function Y1.

**Niveau 1 (sur Y1) — ce qu'on a fait :**
- a) Remplacer la règle `0.0.0.0` par une règle par **IP sortante de la Function** (`for_each` sur `possible_outbound_ip_addresses`, 25 règles). → **Échec réel**, voir section 10.
- b) Règle « IP du PC » **activable/désactivable** avec la variable `allow_workstation_access` (`count = var.allow_workstation_access ? 1 : 0`). Prêt, pas encore fermé.
- c) Entrée de la Function : les appareils sont partout, donc pas de liste d'IP possible → on compte sur la clé (6.1) et, en vrai projet, un WAF / API Gateway. On peut restreindre le site de déploiement (SCM) à son IP.

**Niveau 2 (non fait, optionnel, payant) :** passer en **Flex Consumption** (toujours serverless mais avec VNet), créer un VNet avec 2 sous-réseaux (`snet-func` pour la Function, `snet-pe` pour les private endpoints), un **private endpoint** SQL, une **zone DNS privée** `privatelink.database.windows.net` (pour que le nom du serveur pointe vers l'IP privée), puis `public_network_access_enabled = false` et suppression de toutes les règles de pare-feu. Seule la Function peut alors joindre la base.

**Ce que la segmentation ne corrige pas (6.5.5) :** la Function reste publique (protégée par 6.1, 6.2, le monitoring) ; une Function compromise garde un chemin légitime vers la base (limité par 6.4) ; les secrets et le state ne sont pas protégés par le réseau.

---

## 10. Ce qu'on a découvert pendant le TD

Ce sont de **vrais incidents**, très bons pour l'oral : ils montrent qu'on a compris en lisant les logs.

### a) « Ça marche sans clé » puis 401

Le premier appel sans clé répondait 200 : la version **anonyme** était encore déployée. Après republication avec `AuthLevel.FUNCTION` → 401 sans clé, 200 avec. **Leçon :** modifier le code ne suffit pas, il faut **republier**.

### b) `[000]` et 401 avec la clé

Commandes lancées depuis le mauvais dossier ou dans une nouvelle fenêtre → `$Url` / `$Key` **vides**. `000` = curl n'a jamais joint le serveur. **Leçon :** vérifier ses variables (`"Key length: $($Key.Length)"`) avant d'accuser le cloud.

### c) 500 `Login timeout expired`

La base **serverless** se met en **pause** après 60 min. Le premier appel la réveille, mais le réveil dure plus que le timeout de connexion (30 s) → 500. Un nouvel appel une minute plus tard → 200. **Leçon :** c'est un compromis **coût / disponibilité**, pas un bug de sécurité.

### d) Le pare-feu par IP casse l'application (6.5 niveau 1)

Après avoir remplacé `0.0.0.0` par les 25 IP publiées par Azure :
- POST → 200, mais GET → **500** à chaque fois ;
- dans Application Insights : `Client with IP address '131.189.239.33' is not allowed to access the server (40615)` ;
- `131.189.239.33` n'est **ni** dans `possibleOutboundIpAddresses` **ni** dans `outboundIpAddresses`.

**Explication :** sur **Linux Consumption**, les machines (workers) sont prises dans un **pool partagé** de la région, et la liste d'IP publiée par Azure pour l'application est **incomplète**. Le filtrage par IP échoue donc **au hasard** dès le premier jour.

**Décision :** remettre la règle `0.0.0.0` (l'appli refonctionne : POST 200, GET 200). **Conclusion :** sur Y1, l'isolation réseau fiable de la base est **impossible** ; il faut le niveau 2 (VNet + private endpoint).

---

## 11. Monitoring comme contrôle de sécurité (6.6)

Application Insights est notre **seule fenêtre** sur la Function (pas de log stream en ligne de commande sur Linux Consumption). Tables principales :

| Table | Contient |
|---|---|
| `requests` | Chaque appel : route, code HTTP, durée |
| `traces` | Nos `logger.info/warning` (ex. `Rejected request: ...`) |
| `exceptions` | Les erreurs avec la pile d'appels |

Requête utile (Portail → Application Insights → Logs) :

```kusto
requests
| where timestamp > ago(30m)
| project timestamp, name, resultCode
| order by timestamp desc
```

**Constats réels :**
- Les **401 n'apparaissent pas** dans `requests` : l'hôte refuse avant d'exécuter la Function. Une attaque par force brute sur la clé serait donc **invisible** ici.
- `client_IP` vaut toujours `0.0.0.0` : Application Insights **masque les IP** par défaut (vie privée). On ne peut pas répondre « depuis quelles IP » sans changer ce réglage.
- Les 400 sont visibles deux fois : dans `requests` (code 400) et dans `traces` (warning `Rejected request`).
- Les données arrivent avec **1 à 3 minutes** de retard.

**Première alerte à créer :** un pic de réponses 4xx/5xx, ou d'exceptions SQL (`40615`, `permission denied`). Cycle NIST : **identifier, protéger, détecter, répondre, rétablir**. On ne peut **détecter** que si les logs existaient **avant** l'incident, d'où le monitoring dès le premier `apply`.

---

## 12. Nettoyage (section 7)

À la toute fin du TD, pour ne pas consommer les crédits :

```powershell
cd infra
terraform destroy
az group list --query "[?starts_with(name, 'rg-namecounter')].name" -o tsv   # doit être vide
```

Le groupe du state `rg-tfstate-prod` n'est **pas** géré par ce projet : on le supprime à la fin du cours avec `az group delete --name rg-tfstate-prod`.

---

## 13. Questions probables du prof

**Pourquoi Terraform plutôt que le portail ?**
Reproductible, versionné dans Git, relisible (revue de code), `plan` montre les changements avant de les faire, même résultat à chaque fois, destruction propre.

**Qu'est-ce que le state et pourquoi est-il sensible ?**
Le fichier où Terraform mémorise les ressources créées. Il contient les secrets **en clair**. Il est stocké dans un Storage Azure privé avec accès Entra ID, verrouillage, et jamais dans Git.

**Différence entre authentification, autorisation et chiffrement ?**
Authentification = qui es-tu (clé de fonction). Autorisation = ce que tu as le droit de faire (rôles SQL reader/editor, rôles Key Vault). Chiffrement = personne ne peut lire en route (HTTPS sur la Function, `Encrypt=yes` + TLS 1.2 vers SQL).

**Pourquoi un 401 sans clé ?**
`AuthLevel.FUNCTION` : l'hôte Azure Functions exige `x-functions-key` (ou `?code=`) et refuse avant d'exécuter le code.

**Pourquoi une clé partagée est faible ?**
Si elle fuit, tous les clients sont compromis ; pas de traçabilité par appareil ; pour révoquer, il faut changer la clé pour tout le monde. → identité par appareil.

**L'injection SQL marche-t-elle ?**
Non : requêtes paramétrées (la donnée n'est jamais interprétée comme du SQL) + validation en liste blanche qui refuse `'` et `;` avec un 400.

**Qu'apporte Key Vault ? Est-ce suffisant ?**
Les secrets sortent de la configuration de l'app, l'accès est contrôlé par RBAC et journalisé. Mais le mot de passe existe encore (tfvars, state). Mieux : sans mot de passe, avec l'identité managée + l'authentification Entra sur SQL.

**Qu'est-ce qu'une identité managée ?**
Une identité qu'Azure donne à la Function, sans secret à gérer. Ici elle a le rôle « Key Vault Secrets User » pour lire les secrets.

**Pourquoi deux logins SQL ?**
Moindre privilège : le GET ne peut que lire ; le POST ne peut ni supprimer ni modifier la structure. Si un composant est compromis, les dégâts sont limités.

**Que fait la règle `0.0.0.0` et pourquoi est-elle risquée ?**
Elle autorise **toutes les ressources Azure, de tous les clients Azure**, à tenter une connexion. Seul le mot de passe protège alors la base.

**Pourquoi ne pas l'avoir supprimée ?**
On l'a supprimée et remplacée par les IP de la Function, mais la liste d'IP fournie par Azure était incomplète sur Linux Consumption (IP `131.189.239.33` refusée, erreur 40615) → l'appli cassait. On l'a remise ; la vraie solution est le niveau 2.

**Que faudrait-il pour une base vraiment privée ?**
Un plan qui supporte le VNet (Flex Consumption, Premium ou Dedicated), un VNet avec un sous-réseau pour la Function et un pour les private endpoints, un private endpoint SQL, une zone DNS privée `privatelink.database.windows.net`, puis l'accès public désactivé.

**Pourquoi une zone DNS privée ?**
Pour que le **même nom** `sql-....database.windows.net` pointe vers l'**IP privée** depuis le VNet. Sinon la Function résout l'IP publique et échoue quand l'accès public est fermé.

**Pourquoi le monitoring dès le début ?**
Sur Linux Consumption, c'est le seul moyen de voir les erreurs. Et on ne peut détecter un incident que si les logs existaient avant.

**Que voit-on et que ne voit-on pas dans les logs ?**
On voit les 200, 400, 500 et les exceptions. On ne voit **pas** les 401 dans `requests` (refus par l'hôte), et les IP clientes sont masquées (`0.0.0.0`).

**Pourquoi une erreur 500 « Login timeout expired » ?**
La base serverless était en pause (auto-pause après 60 min) ; le réveil dépasse le timeout de 30 s. Ce n'est pas une faille ; c'est le prix de l'économie.

**Pourquoi `https_only = true` et `min_tls_version` ?**
Forcer le chiffrement en transit et refuser les anciennes versions de TLS vulnérables.

**Pourquoi le code renvoie « Internal error. » et pas l'erreur réelle ?**
Pour ne pas donner d'informations à un attaquant (noms de serveur, structure SQL). Le détail est dans les logs, visibles seulement par nous.

**Pourquoi serverless pour des objets connectés (section 9) ?**
Le nombre d'appareils et leur activité sont imprévisibles : le serverless s'adapte tout seul et on paie à l'usage. Les appareils font le minimum (filtrer, résumer) et la Function stocke le résultat.
