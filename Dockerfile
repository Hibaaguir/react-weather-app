# Étape 1 : On part d'une image Nginx légère (Alpine)
FROM nginx:alpine

# Étape 2 : (Optionnel) On ajoute des métadonnées
LABEL maintainer="hibaaguir"

# Étape 3 : On copie le dossier 'build' généré par Jenkins vers le dossier par défaut de Nginx
# Le pipeline a déjà exécuté 'npm run build', donc le dossier 'build' existe à la racine.
COPY build/ /usr/share/nginx/html

# Étape 4 : On expose le port 80 (interne au conteneur)
# Ton pipeline fait le mapping vers le port 3001 de l'hôte, mais le conteneur écoute sur le 80.
EXPOSE 80

# Étape 5 : Commande de démarrage de Nginx
CMD ["nginx", "-g", "daemon off;"]