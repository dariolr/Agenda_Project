---
name: feedback-deploy-policy
description: I deploy non devono mai essere eseguiti dall'assistente — li fa sempre l'utente
metadata:
  type: feedback
---

Non eseguire mai script di deploy (`deploy_core.sh`, `deploy_backend.sh`, `deploy_frontend.sh`) anche se il contesto lo suggerisce.

**Why:** L'utente vuole controllare personalmente quando e cosa viene deployato.

**How to apply:** Dopo aver modificato il codice, indicare quale script di deploy va eseguito e con quale ambiente (`staging`, `production`, ecc.), ma non eseguirlo.
