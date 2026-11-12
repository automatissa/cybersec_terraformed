# Fiche de révision — Cybersécurité (CM + TD + vidéo)

Pour le devoir : **questions de cours** + **case studies**.
Sources : le cours (`Cybersecurity_260920_142402 (1).pdf`, 108 pages), la vidéo Underscore_ avec Gaël Musquet sur le hacking de voitures (https://www.youtube.com/watch?v=wCDGEjhL6eQ), et le TD (voir [README.md](README.md)).

---

## Sommaire

1. [Les cyberattaques : exemples et chiffres](#1-les-cyberattaques--exemples-et-chiffres)
2. [Cybersécurité : NIST et triade CIA](#2-cybersécurité--nist-et-triade-cia)
3. [Identification et authentification](#3-identification-et-authentification)
4. [Réglementation : NIS, RGPD, PIA](#4-réglementation--nis-rgpd-pia)
5. [Sécuriser une application serverless (lien avec le TD)](#5-sécuriser-une-application-serverless-lien-avec-le-td)
6. [Défense en profondeur](#6-défense-en-profondeur)
7. [Mots de passe, SSO et IAM](#7-mots-de-passe-sso-et-iam)
8. [Réseau : pare-feu, VPN, segmentation](#8-réseau--pare-feu-vpn-segmentation)
9. [Protocoles et chiffrement](#9-protocoles-et-chiffrement)
10. [Pourquoi serverless ? Les objets connectés](#10-pourquoi-serverless--les-objets-connectés)
11. [Mécatronique, durcissement, bus CAN](#11-mécatronique-durcissement-bus-can)
12. [La vidéo : hacking de voitures](#12-la-vidéo--hacking-de-voitures)
13. [Case studies du cours : réponses modèles](#13-case-studies-du-cours--réponses-modèles)
14. [DDoS et OWASP Top 10](#14-ddos-et-owasp-top-10)
15. [Méthode pour un case study](#15-méthode-pour-un-case-study)
16. [Auto-test : questions de cours](#16-auto-test--questions-de-cours)
17. [À retenir en 20 lignes](#17-à-retenir-en-20-lignes)

---

## 1. Les cyberattaques : exemples et chiffres

### Exemples du cours

| Attaque | Ce qui s'est passé | Leçon |
|---|---|---|
| **Samsung** (groupe Lapsus$) | Vol et publication de 190 Go, dont le code source des Galaxy. Lapsus$ a aussi visé Ubisoft, Nvidia, Microsoft | Même les géants sont touchés ; vol de propriété intellectuelle |
| **ENAC** (école de l'aviation civile) | Ransomware : tout le système d'information paralysé, plus de 100 avions cloués au sol | Un rançongiciel bloque l'activité entière (disponibilité) |
| **Ukraine** | Cyberguerre en parallèle de l'invasion : DDoS, *wipers* (malwares qui effacent) ; le satellite Viasat attaqué → coupure Internet en Europe | Les conflits ont un volet cyber ; effets collatéraux |
| **Garmin** (juillet 2020) | Ransomware *WastedLocker* ; entrée probable par phishing ou failles non corrigées ; services coupés dans le monde ; rançon de plusieurs millions (non confirmée) | Former les employés, appliquer les mises à jour, avoir des sauvegardes et un plan de reprise |

### Les 4 motivations des attaquants

| Motivation | Exemples |
|---|---|
| **Déstabiliser** | Déni de service, messages idéologiques, divulgation d'informations |
| **Gains financiers** | Vol d'identité, vol de données personnelles et bancaires, transactions frauduleuses, **rançon** |
| **Idéologie** | Destruction logique ou physique, vol de données stratégiques, divulgation |
| **Obtenir des capacités d'attaque** | Piéger des sites ou logiciels de confiance, espionner le réseau, contourner les mécanismes de sécurité |

### Les 3 chiffres du quiz (à connaître)

| Question | Réponse |
|---|---|
| Durée moyenne d'**interruption** après un malware | **50 jours** |
| Temps moyen pour **détecter** une fuite (2022) | **287 jours** (7 de plus que l'année d'avant) |
| Coût moyen d'une fuite de données (2022) | **4,24 M$** (contre 3,86 M$ avant) |

👉 287 jours de détection : c'est pour ça que la **détection** (logs, monitoring) est essentielle.

### La Cyber Kill Chain

La diapositive est une image : voici le modèle classique (Lockheed Martin, connaissance générale). Ce sont les **7 étapes d'une attaque**. Casser **une seule** étape suffit à arrêter l'attaque.

1. **Reconnaissance** : se renseigner sur la cible.
2. **Armement** (*weaponization*) : préparer l'outil d'attaque (malware, exploit).
3. **Livraison** (*delivery*) : l'envoyer (email de phishing, clé USB, site piégé).
4. **Exploitation** : la faille est déclenchée.
5. **Installation** : le malware s'installe et reste.
6. **Commande et contrôle** (C2) : l'attaquant pilote la machine à distance.
7. **Actions sur l'objectif** : vol, chiffrement (rançon), destruction.

---

## 2. Cybersécurité : NIST et triade CIA

**Définition du cours :** la cybersécurité, c'est assurer la **Confidentialité, l'Intégrité et la Disponibilité** de l'information en la protégeant des attaques et des activités malveillantes.

### Les 5 piliers du NIST (dans l'ordre)

| Pilier | En simple | Contenu du cours |
|---|---|---|
| **1. Identify** (identifier) | Savoir ce qu'on doit protéger | Environnement métier, inventaire des actifs, analyse et gestion des risques, gouvernance |
| **2. Protect** (protéger) | Mettre les protections | Infrastructure, applications, données, gestion des identités et accès (IAM), sensibilisation et formation |
| **3. Detect** (détecter) | Voir les attaques | Surveillance continue, scénarios d'alerte |
| **4. Respond** (répondre) | Réagir pour limiter les dégâts | Gestion d'incident, gestion de crise |
| **5. Recover** (rétablir) | Revenir à la normale | Restaurer les actifs après l'incident |

Moyen mnémotechnique : **I-P-D-R-R** → « **I**l **P**leut **D**onc **R**este **R**angé ».

Dans le TD : Identify = carte d'exposition (6.5.1) ; Protect = clé, validation, Key Vault, rôles ; Detect = Application Insights ; Respond/Recover = logs pour comprendre, `terraform` pour reconstruire.

### La triade CIA (en français : DIC → Disponibilité, Intégrité, Confidentialité)

| Pilier | Définition | Concepts clés |
|---|---|---|
| **Confidentiality** (confidentialité) | Seules les personnes autorisées peuvent lire | **PII** (données qui identifient une personne), **PHI** (données de santé), informations classifiées (secrets industriels, recherche, plans). **Sensibilité** = valeur de l'information, et donc le dommage si elle fuit. Difficulté : protéger tout en laissant les bons utilisateurs accéder, même depuis des appareils peut-être compromis |
| **Integrity** (intégrité) | Les données sont complètes, cohérentes, exactes, non modifiées sans autorisation, au repos, en traitement et en transit | **Intégrité des données** et **intégrité du système** (configuration "connue et saine"). On compare l'état actuel à une **référence** (*baseline*) pour détecter les écarts. **Cohérence** : toutes les copies identiques |
| **Availability** (disponibilité) | Accès **fiable et dans les temps** pour les utilisateurs autorisés | Pas forcément 24h/24 : selon les **besoins métier**. **Criticité** = importance qu'on donne à la disponibilité d'un système pour la mission |

Exemples pour chaque pilier :
- Fuite de données Samsung → **confidentialité**.
- Modifier un montant ou un compteur → **intégrité**.
- Ransomware ENAC, DDoS → **disponibilité**.

---

## 3. Identification et authentification

| Notion | Définition |
|---|---|
| **Identification** | Dire qui on est : reconnaître l'identité d'un utilisateur dans un système (ex. un nom d'utilisateur) |
| **Authentification** | **Prouver** que cette identité est vraie |
| **Autorisation** | Ce qu'on a le droit de faire une fois authentifié |
| **Active Directory (AD)** | Annuaire Microsoft : gère utilisateurs et ressources, attribue des identifiants uniques, gère l'authentification et l'autorisation |
| **LDAP** | Protocole pour interroger un annuaire sur le réseau ; permet par exemple à Linux d'interroger l'AD |
| **Kerberos** | Protocole d'authentification principal de l'AD. Utilise la **cryptographie à clé secrète** et un **tiers de confiance**, et fonctionne pour Linux et Windows |

### Les 3 facteurs d'authentification

| Facteur | Exemple |
|---|---|
| Ce que je **sais** | Mot de passe, code PIN |
| Ce que je **possède** | Jeton (token), carte à puce, téléphone |
| Ce que je **suis** | Biométrie (empreinte, visage) |

**MFA** (authentification multifacteur) = au moins **2 facteurs de catégories différentes**. Deux mots de passe, ce n'est **pas** du MFA.

**Bonnes pratiques :** mots de passe complexes et uniques, jetons, biométrie, et **surveiller** les échecs d'authentification.

---

## 4. Réglementation : NIS, RGPD, PIA

**Objectifs des réglementations :** protéger les données des consommateurs et des organisations, garantir la vie privée, rendre les traitements transparents, élever le niveau de sécurité mondial.

### Les principales réglementations

| Texte | Domaine |
|---|---|
| **RGPD / GDPR** | Données personnelles (Union européenne) |
| **HIPAA** | Données de santé (États-Unis) |
| **PCI DSS** | Données de cartes bancaires |
| **FISMA** | Systèmes d'information fédéraux américains |
| **Directive NIS** | Sécurité des réseaux et systèmes d'information (UE) |
| **ISO/IEC 27001** | Norme internationale de management de la sécurité de l'information |

### Directive NIS (UE)

Elle vise deux types d'acteurs :
- **OES** (Opérateurs de Services Essentiels), dans 7 secteurs : énergie, transport, banques, infrastructures des marchés financiers, santé, eau potable, infrastructures numériques.
- **DSP** (Fournisseurs de Services Numériques) : moteurs de recherche, places de marché en ligne, **cloud**. Les micro et petites entreprises sont exclues.

Elle demande aux États de :
- créer des autorités dédiées (**ANSSI** en France, **BSI** en Allemagne) ;
- coopérer entre eux (échanges entre **CERT**) ;
- identifier leurs OES et DSP ;
- imposer la **notification des incidents** ;
- imposer une sécurité "à l'état de l'art" par des lois nationales.

### RGPD : les 7 principes

1. **Licéité, loyauté, transparence** : traitement légal et expliqué à la personne.
2. **Limitation des finalités** : données collectées pour un but précis, pas d'autre usage sans consentement.
3. **Minimisation** : seulement les données nécessaires.
4. **Exactitude** : données à jour.
5. **Limitation de conservation** : pas plus longtemps que nécessaire.
6. **Intégrité et confidentialité** : traitement sécurisé.
7. **Responsabilité** (*accountability*) : l'organisation doit prouver qu'elle respecte tout ça.

Chiffres clés :
- Amende jusqu'à **20 M€ ou 4 % du chiffre d'affaires mondial** (le plus élevé des deux).
- Notification d'une fuite à l'autorité (la CNIL en France) sous **72 heures** si possible.
- **DPO** (délégué à la protection des données) obligatoire si on traite beaucoup de données sensibles.

### RGPD : les 6 droits des personnes

Accès, rectification, **effacement** (droit à l'oubli), limitation du traitement, **portabilité** (récupérer ses données dans un format standard), opposition.

### Obligations des organisations

Consentement explicite (retirable à tout moment), DPO, notification sous 72 h, **PIA** pour les traitements à risque.

### PIA (Privacy Impact Assessment = analyse d'impact)

Un processus pour **identifier et réduire les risques pour la vie privée** d'un nouveau projet.

**Obligatoire si** (9 critères du cours) :
1. évaluation, notation ou profilage des personnes ;
2. traitement à grande échelle ;
3. données sensibles ;
4. personnes vulnérables (mineurs, salariés, personnes handicapées…) ;
5. décision automatique avec effet important ;
6. usage innovant des données ;
7. surveillance systématique d'un lieu public ;
8. croisement de jeux de données ;
9. traitement qui empêche d'exercer un droit ou d'exécuter un contrat.

**Méthode en 4 étapes :** 1) analyse du **contexte** → 2) analyse des **mesures** → 3) analyse des **risques** → 4) **validation**.

Deux règles :
- Les principes et droits du RGPD **ne se négocient pas**, quel que soit le risque.
- Les risques pour les personnes déterminent les mesures techniques et organisationnelles.

### Exercice PIA du cours (hôpital de la Fondation)

**Scénario :** M. Seldon, accidenté, a besoin d'une transfusion. Un proche remplit un formulaire papier, déposé dans une corbeille dans le couloir, puis retapé par une réceptionniste dans une application hébergée dans un cloud public et utilisée sur smartphone. L'infirmière se trompe de patient (« A+ » alors qu'il est « O- »).

**Risques identifiés dans le cours :**
- données personnelles collectées **non pertinentes** ;
- **pas d'information** sur l'usage des données ;
- **confidentialité non respectée** (formulaire dans une corbeille au milieu du couloir) ;
- **mauvaise qualité** de données à haut risque (formulaire rempli par un proche, puis **ressaisi** → erreurs ; groupe sanguin faux) ;
- risque sur la **disponibilité** (l'application met du temps à démarrer en urgence).

**Note :** ici, le consentement du patient **n'est pas obligatoire**, car il s'agit d'un intérêt **vital**.

**Mesures possibles :**
- formulaire numérique rempli directement, sans ressaisie ;
- vérification de l'identité du patient (bracelet, code-barres) ;
- double contrôle du groupe sanguin ;
- stockage fermé à clé ou numérique avec contrôle d'accès ;
- information du patient et de la famille ;
- ne collecter que le nécessaire ;
- application disponible en mode dégradé ou hors ligne ;
- chiffrement et authentification forte sur le smartphone ;
- hébergeur certifié **HDS** (hébergement de données de santé).

---

## 5. Sécuriser une application serverless (lien avec le TD)

**Le cas d'usage du cours :** imiter un boîtier télématique de voiture (**TCU**) ou un ESP32 / Raspberry Pi qui envoie sa télémétrie (vitesse, température, codes défaut) en **HTTP POST avec TLS 1.2+**. Dans le TD, on le simplifie avec un compteur de prénoms : les principes de sécurité sont les mêmes.

### Avant / après (diapos 47-48)

| Non sécurisé | Sécurisé |
|---|---|
| Function et SQL **serverless** reliés en **HTTP** | **HTTPS** |
| Endpoint public ouvert (0.0.0.0/0), **authentification anonyme** | Authentification via **Entra ID** (ex-Azure AD) |
| Mot de passe dans la configuration | **Azure Key Vault** |
| Base sans protection | SQL avec **TDE** (*Transparent Data Encryption*, chiffrement au repos) et contrôle d'accès fin par **IAM** |
| Aucune détection | **Microsoft Sentinel** (**SIEM** : collecte et corrèle les logs pour détecter les attaques) |
| Exposé directement | **Application Gateway avec WAF** (pare-feu applicatif web) devant |
| Function publique | **Function intégrée à un VNet** avec règles d'accès restreintes |

### Sécuriser une base SQL dans le cloud (diapos 50-52)

| Domaine | Mesures |
|---|---|
| **Réseau** | Pare-feu SQL limité aux IP connues ; **désactiver « Allow Azure services »**, qui ouvre la base à n'importe quel client Azure ; utiliser des **Private Endpoints** (Private Link) dans un VNet |
| **Authentification / autorisation** | Mots de passe forts, gestion par Entra ID, **moindre privilège** |
| **Chiffrement** | **Au repos : TDE** ; **en transit : TLS** |
| **Sauvegarde** | Sauvegardes régulières **et tests de restauration** |
| **Avancé** | **Advanced Threat Protection** (détection d'activité anormale), **Azure Monitor + SQL Auditing**, mises à jour, **MFA** |

### Ce que le TD a montré concrètement

| Mesure du cours | Dans le TD | Résultat |
|---|---|---|
| Authentification | Clé de fonction (`AuthLevel.FUNCTION`) | 401 sans clé, 200 avec |
| Validation (OWASP Injection) | `validate_name` + requêtes paramétrées | Tentative d'injection → 400 |
| Key Vault | Chaînes de connexion dans Key Vault + identité managée | Références « Resolved » |
| Moindre privilège | Deux logins SQL : reader / editor | GET lit, POST écrit, aucun ne supprime |
| Désactiver « Allow Azure services » | Remplacé par les IP de la Function | **A cassé l'appli** : la liste d'IP d'Azure était incomplète sur le plan Y1 → il faut un **Private Endpoint** (plan Flex) |
| Monitoring | Application Insights | Les 401 n'apparaissent pas ; IP masquées |
| TLS | HTTPS + `Encrypt=yes`, TLS 1.2 | Chiffrement en transit |

---

## 6. Défense en profondeur

**Définition :** une stratégie **multicouche** qui empile plusieurs contrôles de sécurité sur toute l'infrastructure. Si une couche tombe, les autres protègent encore.

**Principes :**
- **Sécurité en couches** : périmètre, réseau, poste de travail, application.
- **Mécanismes variés** : **préventifs** (bloquer), **détectifs** (voir), **réactifs** (répondre).

**Exemples :** pare-feu, SIEM, chiffrement, contrôle d'accès, politiques de sécurité.

**Les 4 couches de mise en œuvre :**

| Couche | Exemples |
|---|---|
| Physique | Accès aux bâtiments et aux appareils |
| Réseau | Segmentation, surveillance du trafic, protocoles sécurisés |
| Application | Mises à jour, revues de code, pare-feu applicatif (WAF) |
| Données | Chiffrement au repos et en transit, sauvegardes |

**Bénéfices :** **résilience** (prévenir, détecter, répondre) et protection **globale**.

**Exemple avec le TD :** si la clé de fonction fuit, la validation bloque encore les injections ; si un login SQL fuit, il ne peut que lire ; si tout tombe, les logs permettent de comprendre.

---

## 7. Mots de passe, SSO et IAM

### Mots de passe

- **Forts :** majuscules, minuscules, chiffres et symboles ; **12 caractères minimum** ; imprévisibles (pas de dates, de mots courants ni de suites).
- **Faibles :** informations personnelles, mots courants, mots de passe **par défaut**.
- **Bonnes pratiques :** un mot de passe différent par compte, les changer régulièrement, ne pas réutiliser les anciens.

### Coffres et gestionnaires

KeePass, AWS KMS, Azure Key Vault : stockage **chiffré** et centralisé, génération de mots de passe forts et uniques.

### 3 stratégies d'authentification (diapo 58)

| Stratégie | Bilan |
|---|---|
| Un mot de passe stocké **dans chaque application** | n applis → **n** mots de passe |
| Un mot de passe dans un **annuaire partagé** (AD) | n applis → **1** mot de passe (à retaper partout) |
| Authentification déléguée à un **fournisseur d'identité (IdP)** = **SSO** | n applis → 1 mot de passe **tapé une seule fois** (relation de confiance entre les applis et l'IdP) |

**Avantages du SSO :** moins de « fatigue des mots de passe », moins de temps perdu, moins d'appels au support pour réinitialiser.

### L'IAM (gestion des identités et des accès) en 5 questions

1. **Processus** : comment simplifier les demandes d'accès (qui contacter, qui valide) ? Problème : comptes partagés, attente (« 3 semaines et toujours pas d'accès à l'ERP »).
2. **Simplifier l'accès** : trop de mots de passe → Post-it, fuites ; besoin d'un accès simple depuis le smartphone et le cloud.
3. **Cycle de vie** : arrivées, mobilités, départs (*joiners, movers, leavers*). Risque : un retraité qui garde tous ses droits.
4. **Séparation des tâches** (*segregation of duties*) : la même personne ne doit pas **commander, valider et contrôler** (risque de fraude, exemple de « Jérôme K. »).
5. **Partenaires** : vérifier l'identité des externes, garder des droits légitimes, éviter les doublons (JohnDoe / Jdoe).

### RBAC (Role-Based Access Control)

**Utilisateur → Rôle métier → Profils applicatifs → Applications**, avec éventuellement un **périmètre** (site, portefeuille, montant).
- Un **rôle métier** = une fonction dans l'entreprise (conseiller clientèle, chef d'agence, facturier).
- Un **profil applicatif** = un ensemble de droits dans une application.

**Intérêt :** la couche « rôles » permet aux métiers de comprendre **qui a accès à quoi**. Sans rôles, c'est un plat de spaghettis de droits individuels. Il n'existe pas de modèle RBAC unique.

**Dans le TD :** les rôles SQL `name_reader` / `name_editor` et les rôles Key Vault (« Secrets User » / « Secrets Officer »), c'est du RBAC.

---

## 8. Réseau : pare-feu, VPN, segmentation

### Antivirus

Détecte, bloque et supprime les malwares (virus, vers, ransomwares). Il faut activer la protection en temps réel, faire des scans réguliers et le **mettre à jour**.

### Pare-feu (firewall)

- Barrière entre l'ordinateur et le réseau.
- **Fonctionnement :** chaque règle dit **allow, deny, drop ou log** ; les règles sont lues **dans l'ordre**, et on **s'arrête à la première qui s'applique**.
- Filtre selon : **IP source, IP destination, protocole (TCP, UDP, ICMP), port**.
- **Difficultés :** les règles deviennent complexes, mal décrites, difficiles à faire évoluer, **jamais revues**.
- **Bonnes pratiques :** règles entrantes **et** sortantes, revue régulière.

### VPN

Un **tunnel chiffré** à travers Internet. Il masque l'adresse IP.

| Type | Protocole | Usage |
|---|---|---|
| **User-to-site** | TLS/SSL | Un salarié en télétravail vers le réseau de l'entreprise. MFA recommandé ; vérification du poste possible (mises à jour, antivirus) |
| **Site-to-site** | IPsec | Lien **permanent** entre deux réseaux (entreprise ↔ partenaire) ; les deux boîtiers peuvent être de marques différentes |

À savoir :
- « SSL » est obsolète : on utilise **TLS**, mais tout le monde dit encore SSL. **HTTPS repose aussi sur TLS**.
- Un VPN ne sert à rien pour des applications déjà exposées sur Internet (Office 365…).

**Limites des VPN commerciaux :**
- pas d'**anonymat** complet ;
- aucune protection contre le **phishing** ou les **malwares** ;
- certains fournisseurs **enregistrent** l'activité ;
- **faux sentiment de sécurité** ;
- protège le **transport**, pas l'**appareil** ;
- contourner des restrictions géographiques peut violer les conditions d'utilisation.

### Segmentation réseau

**Diviser** un réseau en sous-réseaux isolés.

**Bénéfices :**
- **Sécurité** : isoler les systèmes critiques et limiter l'impact d'une attaque.
- **Performance** : moins de trafic de diffusion (*broadcast*).
- **Conformité et gestion** plus simples.

**Exemples d'usage :** séparer le Wi-Fi invité du réseau interne ; isoler les objets connectés et l'**OT** (informatique industrielle) ; séparer les services RH et Finance.

**Techniques :** **VLAN** (séparation logique), **sous-réseaux** (*subnetting*), **ACL** sur routeurs et switchs, **pare-feu** entre segments. Il faut ensuite surveiller et revoir les règles **en continu**.

**Méthode :** 1) évaluer les actifs critiques et les flux de données → 2) concevoir l'architecture → 3) mettre en œuvre → 4) surveiller.

**Dans le TD (6.5) :** sous-réseau `snet-func` pour la Function, sous-réseau `snet-pe` pour les private endpoints, base sans accès public. Pour une voiture : la **passerelle** (gateway ECU) qui sépare les bus critiques.

### Rogue Wi-Fi (faux point d'accès)

Un faux réseau Wi-Fi qui imite un vrai (même nom, **SSID**), placé dans un lieu fréquenté pour intercepter les données. Il se fabrique avec un **Raspberry Pi** ou un **Arduino** à bas coût.

---

## 9. Protocoles et chiffrement

### HTTP/REST vs MQTT (télémétrie)

| | HTTP / REST (notre TD) | MQTT (industrie, automobile) |
|---|---|---|
| Modèle | **Requête / réponse** (*pull*) : le client initie toujours | **Publication / abonnement** (*push*) via un **broker**, dans les deux sens |
| Connexion | **Sans état** : ouverte puis fermée à chaque requête | **Persistante** (TCP long avec *heartbeats*) |
| En-tête | **Lourd** (500 à 1000+ octets) | **Léger** (2 octets) |
| Énergie / bande passante | Coûteux à haute fréquence | Minimal : idéal pour les capteurs sur batterie et les réseaux NB-IoT / LTE-M |
| Garantie de livraison | À coder soi-même (réessais) | **QoS native** : 0 = au plus une fois ; 1 = au moins une fois (standard en télémétrie) ; 2 = exactement une fois |
| Usage idéal | Configuration, envoi de logs par lots, diagnostics, API pour humains, données complexes | Flux continu en temps réel (vitesse des roues, tension batterie, événements CAN) |

### Ports à connaître

| Protocole | Non chiffré | Avec TLS |
|---|---|---|
| HTTP | **80** | **443** (HTTPS) |
| MQTT | **1883** | **8883** (MQTTS) |
| SQL Server (TD) | — | 1433 avec `Encrypt=yes` |

### HTTPS / TLS

HTTPS = HTTP + **TLS**. Il apporte 3 choses :
- **Confidentialité** : le **chiffrement** empêche l'espionnage.
- **Intégrité** : on détecte toute modification en route.
- **Authentification** : le **certificat**, délivré par une **autorité de certification (CA)**, prouve l'identité du serveur. Avec le **mTLS** (TLS mutuel), le client prouve aussi la sienne.

Tout cela protège contre l'attaque de **l'homme du milieu** (*Man-in-the-Middle*).

**La poignée de main TLS (*handshake*) :**
1. Client et serveur négocient l'algorithme et les clés.
2. On utilise le **chiffrement asymétrique** pour échanger une clé secrète.
3. On utilise ensuite le **chiffrement symétrique** pour les données, car c'est plus rapide.

C'est le **chiffrement hybride**.

### Symétrique vs asymétrique

| | Symétrique | Asymétrique |
|---|---|---|
| Clés | **Une seule clé secrète**, la même pour chiffrer et déchiffrer | **Deux clés liées** : une **publique** (partagée) et une **privée** (gardée secrète) |
| Exemple | **AES** | **RSA** |
| Vitesse | Rapide, peu de CPU, message chiffré de même taille | Lent |
| Problème | Comment partager la clé sans qu'elle soit volée ? | Impossible en pratique de retrouver la clé privée à partir de la publique |

**Hybride :** l'asymétrique sert à échanger la clé secrète, puis le symétrique chiffre les données (c'est ce que fait TLS).

### Les 3 outils de la cryptographie (diapo 82)

| Outil | Garantit | Comment |
|---|---|---|
| **Chiffrement** | **Confidentialité** | Alice chiffre avec la **clé publique de Bob** ; seul Bob déchiffre avec sa **clé privée** |
| **Hachage** (*hash*) | **Intégrité** | Une empreinte unique du message : si un seul bit change, l'empreinte change |
| **Signature** | **Authentification** (et non-répudiation) | Alice signe l'empreinte avec **sa clé privée** ; tout le monde vérifie avec **sa clé publique** |

⚠️ Vocabulaire : en français, on dit **« chiffrer »**. « Crypter » et « encrypter » sont incorrects (le prof l'a souligné).

---

## 10. Pourquoi serverless ? Les objets connectés

### Pourquoi serverless ? (les « 3 pourquoi » du cours)

Le nombre de véhicules ou d'objets qui envoient des données est **imprévisible**, avec des pics (heures de pointe).

Un **serveur classique** a deux risques :
- **Sous-dimensionné** : le pic dépasse sa capacité → requêtes perdues, données de diagnostic perdues = **atteinte à la disponibilité**.
- **Surdimensionné** : on paie en permanence pour une capacité qui dort.

Le **serverless** :
- **scale out** : il ajoute des instances en moins d'une seconde quand la file de requêtes grossit, et les retire ensuite ;
- le *scale up* (machine plus grosse) existe aussi, mais avec une **interruption**.

### Pourquoi une base de données à part ?

Les instances serverless sont **sans état** (*stateless*) et **éphémères** : fichiers locaux, variables en mémoire et caches **disparaissent** quand l'instance s'arrête. Il faut donc écrire l'état dans un stockage **persistant** externe (Azure SQL Serverless).

C'est la **séparation des responsabilités** : le calcul évolue selon le nombre d'appels, le stockage selon le volume de données.

### Pourquoi le calcul dans le cloud et pas sur l'objet ?

Les microcontrôleurs (ESP32, ARM Cortex-M, Arduino) sont limités :
- **mémoire** : de quelques Ko à quelques Mo ;
- **processeur** : 16 à 240 MHz ;
- **bande passante** : envoyer de la vidéo 4K brute ou tout le trafic CAN (1 Mbit/s) en 5G coûte trop cher et ajoute de la latence.

👉 **L'appareil fait le minimum** (filtrer, résumer, compresser) et le cloud fait le gros calcul.

### Les 3 exemples du cours

| Cas | Sur l'appareil (edge) | Dans le cloud |
|---|---|---|
| **Flotte de voitures autonomes** | Vision IA locale à 20 images/s, commandes de freinage et de direction via CAN, garde seulement les moments intéressants | Réentraînement des modèles sur GPU (PyTorch, TensorFlow) |
| **Batterie de voiture électrique** | Mesure à 1000 Hz, coupure automatique (contacteur pyrotechnique) en cas d'emballement thermique, résumés par minute | Base de séries temporelles, analyse de l'usure de toute la flotte |
| **Maintenance prédictive (vibrations)** | Accéléromètre de 10 à 50 kHz, conversion en spectre de fréquences, ne garde que les pics | Détection d'anomalies (usure des roulements) |

### Stockage sécurisé

Chiffrer (**BitLocker** sur Windows, **FileVault** sur macOS), contrôler les accès, faire des **sauvegardes régulières chiffrées et stockées ailleurs**, choisir un cloud fiable avec **2FA**.

---

## 11. Mécatronique, durcissement, bus CAN

### Bonnes pratiques pour un ingénieur mécatronicien

Mots de passe forts, **mises à jour** du logiciel **et du firmware**, vigilance face au **phishing**, sauvegardes, **2FA**, programmation sécurisée, sécurité réseau, durcissement des appareils. Il faut sécuriser le **matériel autant que le logiciel**, travailler avec l'équipe cybersécurité et se former en continu (exemple du cours : Sodexo, gestion de bâtiments).

### Durcissement d'un appareil (device hardening)

**Définition :** réduire la **surface d'attaque** en supprimant tout ce qui ne sert pas.

1. **Mettre à jour** l'OS et les logiciels (corriger les failles connues).
2. **Supprimer les services et applications inutiles** (moins de portes d'entrée).
3. **Configurer la sécurité** : changer les réglages par défaut, activer le pare-feu, limiter les permissions, utiliser des protocoles sécurisés.
4. **Antivirus et anti-malware**.

### Le bus CAN (Controller Area Network)

**Pourquoi il existe :** relier chaque capteur à chaque calculateur demandait des milliers de câbles, ce qui alourdissait la voiture. Le CAN fait passer tout le monde sur **une seule paire de fils** (CAN_H et CAN_L) qui fait le tour de la voiture.

**Fonctionnement :**
- **Diffusion** (*broadcast*) : chaque calculateur (**ECU**) entend **tous** les messages et filtre lui-même ceux qui le concernent. Il n'y a pas d'envoi point à point.
- **Arbitrage :** logique « ET câblé ». **0 = dominant**, **1 = récessif**. Un **identifiant CAN plus petit = plus prioritaire**.
- **Électrique :**
  - récessif (1) : différence ≈ 0 V (CAN_H = CAN_L = 2,5 V) ;
  - dominant (0) : différence ≈ 2 V (CAN_H = 3,5 V, CAN_L = 1,5 V).

**Failles natives :**
- **aucune authentification** de l'émetteur ;
- **aucun contrôle d'intégrité** (le CRC protège seulement du bruit électrique, pas d'un attaquant) ;
- **aucun chiffrement** ;
- n'importe quel nœud qui envoie un **0 dominant écrase** tous ceux qui envoient un 1.

### Attaque par injection CAN (dominant override)

1. L'attaquant se branche **physiquement** sur un câble CAN accessible (derrière le **passage de roue** ou le **phare**).
2. Son boîtier réveille le bus et envoie des **bits dominants (0) en continu** : les vrais calculateurs ne peuvent plus parler et les trames d'erreur sont aveuglées.
3. Il diffuse de **fausses trames de déverrouillage de l'antidémarrage**, en se faisant passer pour le récepteur de la clé.

**Type d'attaque :** **Man-in-the-Middle physique**, **usurpation de paquets** (*spoofing*) et **déni de service du bus**.

### Défense automobile multicouche

- **Architecture :** des **gateway ECU** séparent les bus critiques (moteur, direction) des bus exposés (diagnostic, carrosserie, phares).
- **Cryptographie AUTOSAR SecOC :** on ajoute aux trames **CAN FD** un **MAC** (code d'authentification de message) et un **compteur de fraîcheur** qui ne fait qu'augmenter.

Ce que la cryptographie apporte sur le CAN :
- **Authenticité** : le message vient bien d'un vrai calculateur.
- **Intégrité** : on détecte toute modification.
- **Fraîcheur / anti-rejeu** : on ne peut pas enregistrer une trame valide et la rejouer plus tard.

---

## 12. La vidéo : hacking de voitures

**Vidéo :** Underscore_, avec **Gaël Musquet** (hacker éthique, cofondateur d'OpenStreetMap France), environ 30 minutes.

### Le contexte : un paradoxe

Les constructeurs laissent parfois des **failles béantes**, mais **verrouillent** ce qui permettrait de réparer ou modifier soi-même sa voiture.

- Une voiture thermique, c'est « une chaudière ». Des **calculateurs** gèrent l'injection et l'explosion pour respecter les normes de pollution (CO₂, particules fines, NOx, oxydes de soufre).
- **Injonctions contradictoires** : le client veut de la puissance, la loi impose des limites (malus écologique). La norme **GSR 2** impose freinage automatique, maintien de voie, limiteur de vitesse adaptatif.
- Les constructeurs doivent faire des voitures **sécurisées** (routière **et** cyber) tout en respectant une **obligation de réparabilité** (UE), pour que le petit garagiste puisse réparer.
- **Verrouillage commercial** (*vendor lock-in*) : vendre la voiture, puis la maintenance, le crédit, les pièces. Exemples :
  - **BMW** : 18 $/mois pour activer des **sièges chauffants** déjà installés (abandonné après la colère des clients) ;
  - mises à jour de **cartographie GPS** vendues des centaines d'euros alors que des cartes libres existent (OpenStreetMap) ;
  - **Porsche en Russie** : le système de suivi **VTS** a été coupé, les voitures ont cru être volées et **ne démarraient plus** (problème de **disponibilité** causé par une dépendance à un service distant).

### Les attaques montrées

| # | Attaque | Comment | Parade |
|---|---|---|---|
| 1 | **Crochetage** (outil *Lishi*) | Outil de la forme de la clé ; on « gratte » les paillettes de la serrure une à une pour les décoder | Serrure de meilleure qualité ; la plupart des voitures s'ouvrent maintenant par radio |
| 2 | **Brouillage** (*jamming*) | On émet sur la fréquence de la clé (**433 / 868 MHz**, 2 GHz). La voiture **ne se verrouille pas** et le conducteur ne s'en rend pas compte (aire d'autoroute, conducteur fatigué) | **Vérifier** que la voiture est bien verrouillée (clignotants, bruit, poignée) |
| 3 | **Rejeu** (*replay*) | Voitures d'avant 2000 : on **enregistre** le signal d'ouverture (Flipper Zero, radio logicielle) et on le **rejoue** | **Codes tournants** (*rolling codes*) : un **nonce** (nombre à usage unique) **chiffré** à chaque appui ; un code déjà entendu est refusé, voire la voiture se met en sécurité |
| 4 | **Attaque relais** (*relay attack*) | Clés **mains libres** qui dialoguent en permanence avec la voiture. Deux complices et deux radios : l'un près de la clé (file d'attente, porte d'entrée), l'autre près de la voiture. Le signal est relayé (Wi-Fi, 4G, câble) : on « **téléporte la clé** » sur des dizaines de mètres → la voiture **s'ouvre et démarre** | **Boîte à clé** qui bloque les ondes (cage de Faraday) ; **antivol de volant** (« back to basics » : le voleur choisit la voiture la plus facile) |
| 5 | **Prise OBD** | Prise de diagnostic **obligatoire** dans l'habitacle. Une fois branché, on accède à **tous les calculateurs** et on peut **enregistrer une nouvelle clé** (« je suis ta nouvelle clé légitime ») | Ne pas laisser l'accès à l'habitacle ; authentification du diagnostic |
| 6 | **Injection CAN par le phare** | Les phares directionnels sont informatisés, donc reliés au CAN. On perce la calandre ou le garde-boue, on tire le câble, on **injecte** l'ordre d'ouverture ou de démarrage | Passerelle qui isole les bus, SecOC (authentification des trames) |
| 7 | **TPMS** (capteur de pression des pneus, obligatoire dans l'UE depuis **2012**) | Il émet **en permanence** sur **433 MHz** : identifiant unique sur **32 bits**, pression, température, batterie. Trame **ni chiffrée, ni signée, ni authentifiée** → **usurpation** possible (voir les scénarios plus bas) | Chiffrer et authentifier les trames ; **valider les valeurs** reçues (bornes) |

**Les 3 façons de perturber une radio (selon G. Musquet) :** **brouiller**, **rejouer**, **relayer**.

**Les scénarios TPMS :**
- **Buffer overflow** (dépassement de tampon) : on envoie une valeur impossible (« le pneu est à **1024 °C** ») codée sur trop peu de bits → le calculateur plante → on peut écrire dans une zone mémoire (par exemple celle qui déclenche l'ouverture ou le démarrage).
- **Pistage et ingénierie sociale contre un convoi** (personnalités, fonds, armes) : on écoute d'abord pour récupérer les identifiants des valves, puis on envoie « pneu dégonflé, température anormale ». La doctrine du chauffeur est de « s'arrêter dès que possible » → le convoi s'arrête là où l'attaquant veut.
- **Signature unique du véhicule** : 4 pneus × 32 bits = **128 bits** qui identifient une voiture précise (pistage). Utilisé en guerre électronique, y compris pour **déclencher des explosifs** (conflits récents).

### Le côté « constructif »

- **Automotive Grade Linux (AGL)** : un Linux open source (basé sur Yocto) pour les tableaux de bord, porté par plusieurs constructeurs (Toyota…). Il tourne sur un **Raspberry Pi** ; un tableau de bord moderne, c'est **une page web** (HTML5, GTK). Il se relie au bus CAN avec un adaptateur USB (**CANable**), que Linux voit comme une **interface réseau**.
- **Rétro-ingénierie :** on appuie plusieurs fois sur le frein et on regarde **quels bits changent** sur le bus → on a trouvé la trame du freinage → on peut la **rejouer**.
- **OpenPilot** (comma.ai, créé par George Hotz) : un boîtier à moins de 1000 $ (comma 3 : caméras, suivi du regard du conducteur en infrarouge) qui **injecte des ordres sur le CAN** pour rendre une voiture **semi-autonome**. Plus de 300 modèles compatibles, plus de 100 millions de km parcourus, données partagées par la communauté.
- **Les tuners** (préparateurs auto) connaissent souvent les voitures mieux que les constructeurs : ils reprogramment la cartographie moteur. Anecdote : la **NASCAR** est née des contrebandiers d'alcool de la Prohibition qui modifiaient leurs voitures pour semer la police.
- Le métier de **hacker éthique** : imaginer les pires scénarios pour aider les forces de l'ordre et anticiper les vols (G. Musquet a « briqué » sa voiture 5 fois en testant).

### Les leçons de cybersécurité de la vidéo

1. **Accès physique = fin de partie** : dès qu'on touche le bus CAN ou la prise OBD, le modèle de confiance s'effondre, car le CAN fait confiance à tout ce qui est branché.
2. **Ne jamais faire confiance aux entrées** : la valeur de 1024 °C non vérifiée provoque un buffer overflow (c'est le même principe que notre `validate_name` dans le TD).
3. **Chiffrement ≠ protection complète** : les codes tournants empêchent le **rejeu**, mais pas le **brouillage** ni le **relais**.
4. **La disponibilité dépend des services distants** (Porsche en Russie).
5. **Les protections simples marchent** : boîte à clé, antivol de volant, vérifier le verrouillage. Défense en profondeur : rendre l'attaque **plus coûteuse** que la voiture d'à côté.
6. **Les mêmes compétences servent à attaquer et à innover** (OpenPilot) : c'est la double nature du hacking.

---

## 13. Case studies du cours : réponses modèles

### Case study 1 : Vecteurs d'attaque automobile et accès physique (diapo 101)

**a) Comparer l'attaque relais et l'injection CAN directe (par le phare).**

| | Attaque relais | Injection CAN (phare) |
|---|---|---|
| Couche | **Radio**, sans fil, à distance | **Physique**, filaire, sur la voiture |
| Ce qu'on attaque | La **communication clé ↔ voiture** (protocole mains libres) | Le **réseau interne** de la voiture |
| Principe | On **prolonge** la portée de la vraie clé : la cryptographie est respectée, mais la **proximité** est falsifiée | On **injecte** de fausses trames (déverrouillage, démarrage) et on écrase les vraies (bits dominants) |
| Matériel | Deux radios logicielles + deux complices | Un boîtier d'injection + percer la calandre ou le garde-boue |
| Traces | Aucune trace physique | Dégâts visibles (trou, câble) |
| Défense | Boîte à clé (Faraday), mesure du **temps de vol** du signal (*distance bounding*), clé UWB, désactiver le mains libres, antivol mécanique | Passerelle qui isole les bus, **SecOC** (MAC + compteur), câbles protégés, détection d'intrusion |

**b) Pourquoi le modèle de confiance de l'antidémarrage s'effondre avec un accès direct au bus CAN ?**
- Le CAN est un bus à **diffusion** **sans authentification** : chaque calculateur croit **n'importe quelle trame** qui porte le bon identifiant.
- L'antidémarrage suppose que seul le **vrai récepteur de clé** envoie la trame « clé valide ». Mais tout nœud branché peut envoyer cette trame.
- Avec l'**arbitrage dominant**, l'attaquant peut même **faire taire** les vrais calculateurs (bits 0 en continu) et prendre leur place.
- Le CRC ne protège que du bruit, pas d'un attaquant. Il n'y a ni chiffrement, ni contrôle d'intégrité, ni anti-rejeu.

👉 La sécurité reposait sur l'idée que **le réseau interne est inaccessible**. Avec un accès physique, cette hypothèse tombe, et toute la sécurité avec.

**c) Mesures physiques et d'architecture.**
- **Architecture :** **gateway ECU** qui sépare les bus critiques (moteur, direction, antidémarrage) des bus exposés (phares, carrosserie, diagnostic OBD) et ne laisse passer que les messages autorisés (liste blanche) = **segmentation**.
- **Cryptographie :** **AUTOSAR SecOC** (MAC + compteur de fraîcheur) sur **CAN FD** → authenticité, intégrité, anti-rejeu. Clés stockées dans un **HSM** (puce sécurisée). Échange authentifié challenge-réponse entre l'antidémarrage et le calculateur moteur.
- **Physique :** câbles CAN **non accessibles** depuis l'extérieur (pas dans les phares ni les passages de roue), connecteurs protégés, capteurs d'intrusion, antivol mécanique.
- **Détection :** **IDS** sur le bus (fréquences anormales, trames inattendues), alerte au propriétaire, journalisation.

C'est l'application de la **défense en profondeur** et de la **segmentation** à la voiture.

### Case study 2 : Vulnérabilités radio et télémétrie (TPMS et codes tournants) (diapo 102)

**Contexte :** le TPMS diffuse pression, température et un **ID unique sur 32 bits**, **en clair** sur **433 MHz**.

**a) Pistage et reconnaissance d'un convoi.**
- L'ID est **unique** et **émis en permanence**, même à l'arrêt. 4 pneus × 32 bits = une **empreinte de 128 bits** qui identifie **un véhicule précis**.
- Avec des récepteurs radio placés sur un trajet, on sait **quand et où** passe une voiture : **pistage** sans GPS ni caméra = atteinte à la **confidentialité** et à la vie privée (donnée de localisation = **donnée personnelle** au sens du RGPD).
- Contre un convoi : on écoute d'abord pour **cataloguer** les ID, on reconnaît le convoi à son passage, puis on **usurpe** la valve (fausse alerte « pneu dégonflé, surchauffe ») pour **forcer l'arrêt** (la doctrine dit de s'arrêter dès que possible) → embuscade, ou déclenchement ciblé.

**b) Corruption mémoire / dépassement de tampon.**
- La trame n'est **ni authentifiée ni signée** : on peut envoyer de **fausses valeurs**.
- Valeur **hors limites** (1024 °C) codée sur peu de bits, ou trame malformée : si le calculateur ne **vérifie pas les bornes**, la valeur **déborde** du tampon → plantage (déni de service, mode dégradé), voire **écriture dans une zone mémoire** choisie (exécution de code, par exemple le déverrouillage).

👉 C'est la même faille que l'**injection** de l'OWASP : **ne jamais faire confiance aux entrées** et **valider** (types, bornes, tailles), exactement comme `validate_name` dans le TD.

**Défenses :** validation stricte des valeurs, langages et compilateurs avec contrôle des tampons, **authentification** des trames TPMS, ID aléatoires ou changeants (vie privée), isolement du récepteur TPMS par la passerelle.

**c) Codes fixes vs codes tournants, et leurs limites.**
- **Code fixe** (avant 2000) : la télécommande envoie **toujours le même code**. On l'enregistre une fois (Flipper Zero), on le **rejoue** → la voiture s'ouvre.
- **Code tournant** : à chaque appui, un **nouveau code** (compteur ou nonce **chiffré**, synchronisé avec la voiture). Un code déjà utilisé est **refusé** → le **rejeu simple ne marche plus**.

**Pourquoi ils restent vulnérables :**
- **Brouillage** : on empêche la voiture de recevoir l'ordre de verrouillage ; elle reste ouverte et le conducteur ne remarque rien. Le chiffrement ne protège pas la **disponibilité** du canal radio.
- **Brouillage + capture** (type « RollJam ») : on brouille et on enregistre le 1er code ; le conducteur réappuie, on brouille et on enregistre le 2e, et on envoie le 1er (la voiture s'ouvre normalement). L'attaquant garde le **2e code, encore jamais utilisé**, pour plus tard.
- **Relais** : pour les clés mains libres, l'attaquant ne casse rien, il **transporte** le vrai échange en temps réel. Le code est valide et frais : la cryptographie est respectée, seule la **distance** est trompée.

👉 La cryptographie protège la **confidentialité et l'intégrité** du message, mais **pas** le canal radio (brouillage) ni la **proximité** (relais).

**Défenses :** mesure du **temps de vol** (*distance bounding*, clés **UWB**), délai d'expiration court des codes, **détecteur de brouillage** + confirmation de verrouillage, boîte de Faraday, antivol mécanique.

---

## 14. DDoS et OWASP Top 10

### DDoS (déni de service distribué)

- **Définition :** de **nombreuses machines compromises** (un **botnet**) inondent une cible de requêtes. Le service n'est plus disponible pour les vrais utilisateurs.
- **Pilier CIA touché :** la **disponibilité**.
- **Conséquences :** perte de chiffre d'affaires, atteinte à la **réputation**, et parfois une **diversion** pour cacher une autre attaque.
- **Protections :**
  - **redondance** réseau ;
  - **filtrage** du trafic malveillant ;
  - **plan de réponse** prêt à l'avance ;
  - audits réguliers ;
  - services anti-DDoS spécialisés qui absorbent l'attaque (Azure DDoS Protection, CDN, WAF).
- **Dans le TD :** le serverless **s'adapte à la charge**, mais une attaque DDoS ferait **exploser la facture** (« déni de portefeuille »). La clé de fonction n'empêche pas l'inondation, puisque les 401 sont gérés par l'hôte et invisibles dans les logs. Il faudrait **limiter le débit** (*rate limiting*) avec un WAF ou une API Gateway.

### OWASP Top 10

L'**OWASP** est une organisation à but non lucratif qui publie le **Top 10**, un document de référence sur les **risques les plus courants** des applications web.

| Risque | Explication | Parade (cours) | Dans le TD |
|---|---|---|---|
| **Injection** (SQL, OS, LDAP) | Des données non fiables sont envoyées à un interpréteur comme une **commande** | API sûre, **requêtes paramétrées** | `?` dans les requêtes + `validate_name` → 400 |
| **Authentification défaillante** (*broken authentication*) | Mots de passe, clés ou sessions mal protégés | **MFA**, gestion de session sécurisée | Clé de fonction (une seule, partagée = faible) |
| **Exposition de données sensibles** | Données (banque, santé, personnelles) mal protégées | **Chiffrer au repos et en transit**, **minimiser** les données | HTTPS, TLS vers SQL, Key Vault, « Internal error » sans détails |
| **XSS** (*Cross-Site Scripting*) | Le pirate fait exécuter un script dans le navigateur de la victime (vol de session, redirection) | Frameworks qui **échappent** automatiquement, **CSP** (*Content Security Policy*) | Non concerné (pas de page web), mais la validation limite les caractères |

---

## 15. Méthode pour un case study

Une structure qui marche pour toute étude de cas :

1. **Contexte** : de quoi s'agit-il ? Quels **actifs** faut-il protéger (voiture, données, service) ?
2. **Menace** : qui attaque (voleur, État, hacktiviste) et **pourquoi** (les 4 motivations) ?
3. **Vecteur** : **comment** ? Accès physique, radio, réseau, Internet, humain (phishing).
4. **Faille** : quelle **faiblesse** est exploitée (pas d'authentification, pas de chiffrement, entrée non validée, mot de passe faible, mise à jour manquante) ?
5. **Impact** : quel pilier **CIA** est touché ? Conséquences (financières, sécurité des personnes, réputation, légales comme le RGPD) ?
6. **Contre-mesures** en **défense en profondeur** :
   - **préventives** (bloquer) / **détectives** (voir) / **correctives** (réagir) ;
   - **techniques** (chiffrement, segmentation) / **organisationnelles** (formation, procédures) / **physiques** ;
   - si possible, classer avec le **NIST** : Identify, Protect, Detect, Respond, Recover.
7. **Limites** : ce que les mesures **ne règlent pas** (montre l'esprit critique).

**Astuce :** reliez toujours à un exemple du cours ou du TD, par exemple : « comme dans le TD où le pare-feu par IP a échoué, une seule couche ne suffit pas ».

---

## 16. Auto-test : questions de cours

Cachez la colonne de droite et répondez.

| Question | Réponse |
|---|---|
| Que veut dire CIA ? | Confidentialité, Intégrité, Disponibilité (*Availability*) |
| Les 5 piliers du NIST ? | Identify, Protect, Detect, Respond, Recover |
| Temps moyen de détection d'une fuite (2022) ? | 287 jours |
| Coût moyen d'une fuite (2022) ? | 4,24 M$ |
| Interruption moyenne après un malware ? | 50 jours |
| Les 4 motivations des attaquants ? | Déstabiliser, gains financiers, idéologie, obtenir des capacités d'attaque |
| Identification ou authentification ? | Identification = dire qui on est ; authentification = le prouver |
| Les 3 facteurs d'authentification ? | Ce que je sais, ce que je possède, ce que je suis |
| Kerberos ? | Protocole d'authentification de l'AD, à clé secrète, avec un tiers de confiance |
| LDAP ? | Protocole pour interroger un annuaire (ex. Linux → AD) |
| Amende maximale RGPD ? | 20 M€ ou 4 % du CA mondial (le plus élevé des deux) |
| Délai de notification d'une fuite (RGPD) ? | 72 heures |
| Les 6 droits RGPD ? | Accès, rectification, effacement, limitation, portabilité, opposition |
| Les 7 principes RGPD ? | Licéité/loyauté/transparence, finalité, minimisation, exactitude, conservation limitée, intégrité/confidentialité, responsabilité |
| PIA ? | Analyse d'impact sur la vie privée : contexte → mesures → risques → validation |
| OES et DSP (NIS) ? | Opérateurs de services essentiels ; fournisseurs de services numériques (moteurs de recherche, places de marché, cloud) |
| Défense en profondeur ? | Plusieurs couches de sécurité variées (préventives, détectives, réactives) |
| SSO ? | Une seule authentification auprès d'un fournisseur d'identité (IdP) pour toutes les applis |
| RBAC ? | Droits attribués par rôle métier, pas par personne |
| Séparation des tâches ? | La même personne ne commande pas, ne valide pas et ne contrôle pas |
| Comment un pare-feu lit-il ses règles ? | Dans l'ordre, et s'arrête à la première qui s'applique |
| VPN site-to-site vs user-to-site ? | IPsec entre deux réseaux (permanent) ; TLS entre un utilisateur et un réseau |
| Une limite d'un VPN commercial ? | Pas d'anonymat, pas de protection contre le phishing ou les malwares, logs possibles, faux sentiment de sécurité |
| Rogue Wi-Fi ? | Faux point d'accès qui imite un vrai (même SSID) pour intercepter les données |
| Techniques de segmentation ? | VLAN, sous-réseaux, ACL, pare-feu |
| Ports HTTPS et MQTTS ? | 443 et 8883 (non chiffrés : 80 et 1883) |
| QoS 1 en MQTT ? | Au moins une fois (le standard en télémétrie) |
| Symétrique vs asymétrique ? | Une clé secrète (AES, rapide) vs une paire publique/privée (RSA, lent) |
| Chiffrement hybride ? | Asymétrique pour échanger la clé, puis symétrique pour les données |
| Chiffrement / hachage / signature ? | Confidentialité / intégrité / authentification |
| Les 3 apports de TLS ? | Confidentialité, intégrité, authentification du serveur |
| TDE ? | *Transparent Data Encryption* : chiffrement au repos d'une base SQL |
| Pourquoi désactiver « Allow Azure services » ? | Ça ouvre la base à tous les clients Azure ; mieux vaut un Private Endpoint |
| Pourquoi serverless pour l'IoT ? | Charge imprévisible : évite le sous- et le surdimensionnement, adaptation automatique |
| Pourquoi une base externe ? | Les instances serverless sont sans état et éphémères |
| Device hardening ? | Réduire la surface d'attaque : mises à jour, retirer l'inutile, configurer, antivirus |
| Faille principale du CAN ? | Pas d'authentification, pas d'intégrité, pas de chiffrement ; le dominant écrase tout |
| Bit dominant sur le CAN ? | 0 ; un identifiant plus petit est prioritaire |
| SecOC ? | MAC + compteur de fraîcheur sur les trames CAN FD : authenticité, intégrité, anti-rejeu |
| Rejeu vs relais ? | Rejeu = rejouer **plus tard** un signal enregistré ; relais = transmettre **en direct** pour tromper la distance |
| Pourquoi les codes tournants ne suffisent pas ? | Ils bloquent le rejeu, mais pas le brouillage ni le relais |
| TPMS : 2 risques ? | Pistage (ID unique 32 bits en clair) et usurpation ou buffer overflow (valeurs non validées) |
| DDoS ? | Un botnet inonde une cible → atteinte à la disponibilité |
| Parade OWASP contre l'injection ? | Requêtes paramétrées / API sûre (+ validation) |
| Parade OWASP contre le XSS ? | Échappement automatique + CSP |
| « Crypter » ou « chiffrer » ? | **Chiffrer** |

---

## 17. À retenir en 20 lignes

1. Cybersécurité = protéger la **Confidentialité, l'Intégrité et la Disponibilité**.
2. NIST : **Identifier → Protéger → Détecter → Répondre → Rétablir**.
3. On met **287 jours** à détecter une fuite : sans logs, on est aveugle.
4. **Identifier ≠ authentifier ≠ autoriser**. MFA = 2 facteurs de **types différents**.
5. RGPD : 7 principes, 6 droits, **72 h**, **4 % / 20 M€**, DPO, PIA.
6. **Défense en profondeur** : plusieurs couches ; une seule ne suffit jamais.
7. **Moindre privilège** + **RBAC** + **séparation des tâches**.
8. **SSO** : une authentification, un fournisseur d'identité, moins de mots de passe.
9. Pare-feu : règles lues **dans l'ordre**, première qui s'applique. Les règles se **revoient**.
10. VPN : tunnel chiffré, mais **pas** un bouclier universel.
11. **Segmentation** : isoler le critique (VLAN, sous-réseaux, ACL, pare-feu ; private endpoint dans le cloud).
12. TLS : **chiffrement + intégrité + authentification**. HTTPS sur 443, MQTTS sur 8883.
13. **Symétrique** rapide, **asymétrique** pour échanger les clés : TLS fait de l'**hybride**.
14. **Chiffrement** = confidentialité, **hachage** = intégrité, **signature** = authentification.
15. **Serverless** pour une charge imprévisible ; **sans état**, donc une base externe ; l'appareil fait le minimum.
16. Le **CAN** fait confiance à tout le monde : **accès physique = fin de partie**. Parades : **passerelle + SecOC**.
17. Radio : **brouiller, rejouer, relayer**. Les codes tournants ne bloquent **que le rejeu**.
18. **Ne jamais faire confiance aux entrées** : injection SQL (TD) = buffer overflow TPMS (vidéo) = même principe.
19. **OWASP** : injection, authentification, données sensibles, XSS → requêtes paramétrées, MFA, chiffrement, CSP.
20. Les protections **simples** comptent aussi : boîte à clé, antivol, mises à jour, formation contre le phishing.
