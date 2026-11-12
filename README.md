# Le TD expliqué simplement

Ce qu'il faut **comprendre** pour répondre aux questions du prof. Pas de code : seulement les idées.

---

## 1. Qu'est-ce qu'on a construit ?

Une petite application dans le cloud (Azure). On lui envoie un prénom, elle compte combien de fois elle l'a vu et répond :

> *hello Alice this is your 17th call*

Elle a **3 parties principales** :

| Partie | C'est quoi | Comparaison |
|---|---|---|
| **La Function** | Le programme qui répond | Le vendeur du magasin |
| **La base de données** | L'endroit où les compteurs sont écrits | Le cahier des ventes |
| **Key Vault** | Le coffre-fort des mots de passe | Le coffre du magasin |

Et une partie pour **observer** : **Application Insights**, ce sont les caméras de surveillance. On y voit chaque appel et chaque erreur.

---

## 2. Les idées de base

**Le cloud** : des ordinateurs de Microsoft qu'on loue. On paie seulement ce qu'on utilise.

**Serverless** : on ne s'occupe d'aucun serveur. Azure allume le programme quand quelqu'un l'appelle et l'éteint après. Pratique quand on ne sait pas combien d'utilisateurs viendront.

**Terraform** : au lieu de cliquer partout dans Azure, on **décrit** ce qu'on veut dans des fichiers texte, et Terraform le construit.
- On peut tout reconstruire à l'identique.
- On voit **avant** ce qui va changer (`plan`), puis on applique (`apply`).
- On peut tout supprimer d'un coup (`destroy`).

**Le "state" de Terraform** : le carnet où Terraform note tout ce qu'il a construit. Il contient des **mots de passe en clair**, donc on le range dans un stockage Azure protégé, **jamais** sur GitHub.

---

## 3. Phase 1 : faire marcher l'application

On construit tout, on teste, ça marche. Mais c'est **volontairement pas sécurisé** :
- n'importe qui peut appeler l'application ;
- le mot de passe "administrateur" de la base est visible dans les réglages ;
- on accepte n'importe quel texte comme prénom ;
- la base accepte des connexions venant de tout Azure.

La Phase 2 corrige tout ça, une protection à la fois.

---

## 4. Phase 2 : sécuriser (le magasin)

| Étape | En simple | Comparaison |
|---|---|---|
| **6.1 La clé** | Sans clé secrète, l'appli refuse (**401**). Avec la clé : **200** | Il faut un badge pour entrer |
| **6.2 La validation** | L'appli refuse les prénoms bizarres, comme une tentative de piratage (**400**) | Le caissier refuse les faux billets |
| **6.3 Le coffre-fort** | Les mots de passe ne sont plus dans les réglages, ils sont dans Key Vault. L'appli a sa propre identité pour ouvrir le coffre, sans mot de passe | Les clés du magasin sont au coffre, pas sous le paillasson |
| **6.4 Deux comptes** | Un compte qui peut seulement **lire**, un autre qui peut **écrire**. Aucun ne peut tout casser | L'employé du ménage a la clé du couloir, pas celle de la caisse |
| **6.5 Le réseau** | Limiter **qui peut même atteindre** la base | Fermer la porte de derrière, pas seulement la caisse |
| **6.6 La surveillance** | Lire les logs pour voir les attaques et les erreurs | Regarder les caméras |

**L'idée générale : la défense en profondeur.** On empile plusieurs protections. Si l'une tombe, les autres tiennent encore.

---

## 5. Trois mots à ne pas mélanger

| Mot | Question | Dans le TD |
|---|---|---|
| **Authentification** | *Qui es-tu ?* | La clé (6.1) |
| **Autorisation** | *Qu'as-tu le droit de faire ?* | Les deux comptes lecture / écriture (6.4) |
| **Chiffrement** | *Quelqu'un peut-il lire en route ?* | HTTPS : les données voyagent dans une enveloppe scellée |

⚠️ La clé n'est **pas** du chiffrement : c'est un badge, pas une enveloppe.

---

## 6. Ce qui s'est passé pendant le TD (les histoires à raconter)

**1. "Ça marchait sans clé."**
L'ancienne version sans protection était encore en ligne. Après avoir republié la nouvelle version, sans clé → refusé.
👉 Changer le code ne suffit pas, il faut le **republier**.

**2. Erreur 500 de temps en temps.**
La base de données **s'endort** après 1 heure sans utilisation, pour économiser de l'argent. Le premier appel la réveille, mais trop lentement, et échoue. Une minute après, ça marche.
👉 Ce n'est pas un problème de sécurité, c'est le prix de l'économie.

**3. Le pare-feu qui a cassé l'appli (le plus important).**
On a voulu dire à la base : *"accepte seulement les adresses de notre application"*, avec la liste donnée par Azure. Mais **la liste d'Azure était incomplète** : l'appli utilisait parfois une adresse absente de la liste, donc la base la refusait. On a remis l'ancienne règle.
👉 Avec l'offre la moins chère d'Azure, bloquer par adresse **ne marche pas de façon fiable**. La vraie solution est un **réseau privé**, qui demande une offre plus chère (niveau 2, pas fait).

**4. Ce que les caméras ne voient pas.**
Les appels refusés faute de clé (**401**) **n'apparaissent pas** dans les logs, et les adresses des visiteurs sont masquées.
👉 Quelqu'un qui essaierait de deviner la clé passerait inaperçu.

---

## 7. Les limites (ce qui n'est pas parfait)

- **Une seule clé pour tout le monde** : si elle fuit, tout le monde peut entrer. Mieux : un badge **par appareil**.
- **Le mot de passe de la base existe toujours** : on l'a juste rangé dans le coffre. Mieux : **aucun mot de passe**, l'appli prouve son identité directement à la base (identité managée).
- **La base reste joignable depuis Azure** : seul un réseau privé règlerait ça.
- **L'application elle-même reste publique** : normal, les utilisateurs doivent pouvoir l'appeler. Elle est protégée par la clé, la validation et la surveillance.

---

## 8. Petit lexique

| Mot | Sens |
|---|---|
| **200** | OK |
| **400** | Ta demande est incorrecte (prénom invalide) |
| **401** | Tu n'as pas le droit (pas de clé) |
| **500** | Le serveur a eu un problème |
| **Moindre privilège** | Donner seulement les droits nécessaires, pas plus |
| **Identité managée** | Une "carte d'identité" donnée par Azure à l'appli, sans mot de passe |
| **Injection SQL** | Piratage qui cache des ordres dans un champ texte. Bloqué ici deux fois : par la validation, et parce que la base traite le prénom comme du texte, jamais comme un ordre |
| **Logs** | Le journal de tout ce qui se passe |
| **commit / push** | Enregistrer son travail, puis l'envoyer sur GitHub |

---

## 9. Questions probables du prof (réponses courtes)

**Pourquoi Terraform plutôt que cliquer dans Azure ?**
On peut tout reconstruire à l'identique, voir les changements avant de les faire, et garder l'historique dans Git.

**Pourquoi le "state" est-il sensible ?**
Il contient les mots de passe en clair. On le garde dans un stockage Azure protégé, jamais sur GitHub.

**Pourquoi 401 sans la clé ?**
L'application exige la clé avant même de lancer le code.

**Pourquoi une seule clé partagée est faible ?**
Si elle fuit, tout le monde entre, et on ne sait pas qui a appelé. Mieux : une identité par appareil.

**Le piratage par injection SQL marche-t-il ?**
Non : la validation refuse le prénom, et même sans elle, la base le traiterait comme du simple texte.

**À quoi sert Key Vault ? Est-ce suffisant ?**
À sortir les mots de passe des réglages de l'appli. Pas suffisant : le mot de passe existe encore. L'idéal, c'est de ne plus avoir de mot de passe du tout.

**Pourquoi deux comptes pour la base ?**
Moindre privilège : si une partie est piratée, l'attaquant peut seulement lire, ou seulement ajouter. Il ne peut pas tout supprimer.

**Pourquoi la règle de pare-feu "Azure" est-elle risquée ?**
Elle laisse **tous les clients d'Azure** tenter de se connecter. Seul le mot de passe protège alors la base.

**Pourquoi ne l'avez-vous pas supprimée ?**
On l'a fait, mais l'appli a cassé : la liste d'adresses d'Azure était incomplète. Il faudrait un réseau privé.

**Pourquoi surveiller dès le début ?**
C'est le seul moyen de voir les erreurs. Et on ne peut pas détecter une attaque si les logs n'existaient pas avant.

**Que ne voit-on pas dans les logs ?**
Les appels refusés sans clé (401) et les vraies adresses des visiteurs.

**Pourquoi serverless pour des objets connectés ?**
On ne sait pas combien d'objets vont appeler ni quand. Le serverless s'adapte tout seul et on paie à l'usage.

**Pourquoi l'appli répond "Internal error" et pas la vraie erreur ?**
Pour ne pas donner d'indices à un pirate. La vraie erreur est dans les logs, que seuls nous pouvons lire.

---

Pour aller plus loin : [EXPLAINED-SIMPLY.md](EXPLAINED-SIMPLY.md) (version anglaise), [TESTS.md](TESTS.md) (tests à lancer), [Phase2-Notes.md](Phase2-Notes.md) (détails techniques).
