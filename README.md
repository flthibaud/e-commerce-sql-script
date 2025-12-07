# Script SQL pour Projet E-commerce - BUT Informatique

## Contexte

Ce projet a été réalisé dans le cadre du module de **Programmation SQL** du BUT Informatique. L'objectif est de concevoir et d'implémenter la base de données pour une application de e-commerce simple.

Le script `script.sql` contient l'ensemble des instructions SQL pour créer la structure de la base de données, y insérer des données de test et implémenter des logiques métiers via des déclencheurs (triggers).

## Structure du Script

Le script est organisé en plusieurs parties, exécutées dans l'ordre :

1.  **Création de la base de données** :
    *   La base de données `iutdb_ecommerce` est créée avec un encodage `utf8mb4`.

2.  **Création des tables** :
    *   Les tables sont créées sans contraintes dans un premier temps pour éviter les problèmes de dépendances.
    *   Les tables principales sont : `articles`, `categories`, `users`, `orders`, `order_lines`.
    *   Des tables de suivi sont également présentes : `order_history` et `stock_movements`.

3.  **Ajout des contraintes** :
    *   **Contraintes d'intégrité** :
        *   Clés primaires et étrangères pour assurer la cohérence des relations.
        *   Contraintes `UNIQUE` pour les champs qui doivent être uniques (ex: `sku` des articles, `email` des utilisateurs).
    *   **Contraintes de vérification (`CHECK`)** :
        *   Vérification de la validité du modèle intervallaire pour les catégories (`border_right > border_left`).

4.  **Déclencheurs (Triggers)** :
    *   Plusieurs déclencheurs sont mis en place pour automatiser des actions et garantir l'intégrité des données :
    *   **`users`**:
        *   `trg_users_bi` / `trg_users_bu`: Valide la complexité du mot de passe et le crypte en SHA1 avant insertion ou mise à jour.
    *   **`orders`**:
        *   `trg_orders_bi`: Hydrate les informations de l'utilisateur dans la commande lors de sa création.
        *   `trg_orders_ai`: Génère un numéro de commande unique.
        *   `trg_orders_au`: Gère les mouvements de stock et l'historique des statuts lors de la mise à jour d'une commande (ex: passage à "paid" ou "cancelled").
    *   **`order_lines`**:
        *   `trg_order_lines_bi`: Récupère les informations de l'article (snapshot) et calcule les totaux de la ligne.
        *   `trg_order_lines_bu`: Recalcule les totaux si la quantité est modifiée.
        *   `trg_order_lines_ai` / `au` / `ad`: Mettent à jour les totaux de la commande parente après une insertion, modification ou suppression d'une ligne.
    *   **`stock_movements`**:
        *   `trg_stock_movements_bi` / `ai`: Met à jour la quantité en stock de l'article concerné après un mouvement.

5.  **Jeu de test** :
    *   Un jeu de données initial est inséré pour peupler les tables `articles`, `categories`, `users` et les tables de liaison.
    *   Ces données permettent de tester le fonctionnement de la base et des déclencheurs. Pour tester les déclencheurs, il faut effectuer des opérations `INSERT`, `UPDATE` et `DELETE` sur les tables `orders` et `order_lines`.

## Procédures stockées

TODO
