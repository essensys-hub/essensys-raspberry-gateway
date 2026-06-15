# Accès local

Accès aux services Essensys depuis le réseau local (LAN).

!!! tip "Gateway CM5 (dual-NIC) : `mon.essensys.local` en mDNS"
    Sur la [Gateway CM5](../installation/gateway-cm5.md), l'accès local utilisateur se
    fait en **HTTPS** sur `https://mon.essensys.local/`, diffusé automatiquement en
    **mDNS** (service `avahi-publish`) — **aucune configuration DNS ni `/etc/hosts`
    n'est nécessaire** sur les postes du LAN. Le certificat étant auto-signé pour le
    nom `.local`, le navigateur affiche un avertissement à accepter une fois.

    Le nom `mon.essensys.fr` reste, lui, réservé au **segment armoire** (eth1), où il
    résout vers l'IP privée de la gateway (`10.0.1.1`).

## URLs locales

- **Frontend** : `http://mon.essensys.fr/` ou `http://<ip-raspberry>/` (Pi 4 mono-interface) — `https://mon.essensys.local/` (Gateway CM5)
- **API** : `http://mon.essensys.fr/api/*`
- **Health check** : `http://mon.essensys.fr/health`

## Configuration DNS locale

Pour que `mon.essensys.fr` fonctionne sur une installation **mono-interface**, configurer le DNS sur votre routeur ou utiliser `/etc/hosts`.

### Via /etc/hosts

Sur chaque machine qui doit accéder au Raspberry Pi :

```bash
sudo nano /etc/hosts
```

Ajouter :
```
192.168.1.101 mon.essensys.fr
```

### Via routeur DNS

Configurer le DNS sur votre routeur pour que `mon.essensys.fr` pointe vers l'IP du Raspberry Pi.

Voir [Configuration Routeur](../router/index.md) pour plus de détails.

## Test de l'accès

### Test frontend

```bash
# Depuis un navigateur
http://mon.essensys.fr/

# Ou via curl
curl http://mon.essensys.fr/
```

### Test API

```bash
# Health check
curl http://mon.essensys.fr/health

# API serverinfos
curl http://mon.essensys.fr/api/serverinfos
```

## Sécurité locale

- **Pas d'authentification** : L'accès local est ouvert (pas de mot de passe)
- **HTTP uniquement** : Pas de HTTPS en local
- **Réseau local uniquement** : Les services ne sont pas accessibles depuis Internet

## Dépannage

### Impossible d'accéder au frontend

1. Vérifier que Nginx est démarré :
```bash
sudo systemctl status nginx
```

2. Vérifier que le port 80 est ouvert :
```bash
sudo netstat -tlnp | grep :80
```

3. Vérifier la résolution DNS :
```bash
ping mon.essensys.fr
```

### Les API ne fonctionnent pas

1. Vérifier que le backend est démarré :
```bash
sudo systemctl status essensys-backend
```

2. Tester directement le backend :
```bash
curl http://localhost:7070/health
```




