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

4.  **Procédures stockées et fonctions** :
    *   Utilisées par les triggers pour éviter la duplication : validation/hachage des mots de passe, hydratation des données utilisateur/produit, contrôle du stock, calcul des totaux de ligne et de commande, génération du numéro de commande, historisation des statuts.
    *   Fonctions d'affichage : libellé de statut (`fn_order_status_label`), niveau de stock (`fn_article_stock_level`).

5.  **Vues** :
    *   Vues de reporting : chiffre d'affaires quotidien/mensuel, articles les plus vendus, clients les plus actifs, alerte stock, chiffre d'affaires par catégorie.

6.  **Déclencheurs (Triggers)** :
    *   Plusieurs déclencheurs sont mis en place pour automatiser des actions et garantir l'intégrité des données :
    *   **`users`**:
        *   `trg_users_bi` / `trg_users_bu`: Valident la complexité du mot de passe via `proc_user_validate_and_hash_password` (SHA1) avant insertion ou mise à jour.
    *   **`orders`**:
        *   `trg_orders_bi`: Hydrate l'utilisateur (`proc_order_hydrate_user`), force le statut `draft`, génère le numéro de commande via `proc_generate_order_number`.
        *   `trg_orders_au`: Historise les changements de statut via `proc_log_order_status` et pilote les mouvements de stock sur passage en `paid`/`cancelled`.
    *   **`order_lines`**:
        *   `trg_order_lines_bi` / `trg_order_lines_bu`: Hydratent l'article (`proc_order_line_hydrate_article`), contrôlent le stock (`proc_check_stock`), calculent les totaux de ligne (`proc_order_line_compute_totals`).
        *   `trg_order_lines_ai` / `au` / `ad`: Recalculent les totaux de la commande via `proc_order_recompute_totals`.
    *   **`stock_movements`**:
        *   `trg_stock_movements_bi` / `ai`: Met à jour la quantité en stock de l'article concerné après un mouvement.

7.  **Jeu de test** :
    *   Un jeu de données initial est inséré pour peupler les tables `articles`, `categories`, `users` et les tables de liaison.
    *   Ces données permettent de tester le fonctionnement de la base et des déclencheurs. Pour tester les déclencheurs, il faut effectuer des opérations `INSERT`, `UPDATE` et `DELETE` sur les tables `orders` et `order_lines`.

## Procédures stockées

Principales procédures utilitaires (appelées par les triggers) :

- `proc_user_validate_and_hash_password(INOUT p_password)`: valide la complexité et retourne le hash SHA1.
- `proc_order_hydrate_user(IN p_user_id, OUT ...)`: hydrate les champs utilisateur dans `orders`.
- `proc_order_line_hydrate_article(IN p_article_id, OUT ...)`: hydrate les champs article dans `order_lines`.
- `proc_check_stock(IN p_article_id, IN p_required_qty)`: lève une erreur si le stock est insuffisant.
- `proc_order_line_compute_totals(IN p_unit_price, IN p_vat_rate, IN p_qty, OUT ...)`: calcule `line_net`, `line_vat`, `line_incl_vat`.
- `proc_order_recompute_totals(IN p_order_id)`: recalcule les totaux d'une commande.
- `proc_log_order_status(IN p_order_id, IN p_old_status, IN p_new_status)`: historise un changement de statut.
- `proc_generate_order_number(IN p_order_id, OUT p_order_number)`: génère un numéro de commande mensuel.

## Tests

### Utilisateurs

- Utilisateurs : insertion OK + erreur
```sql
-- OK : mot de passe valide, sera haché par la proc/trigger
INSERT INTO users (firstname, lastname, email, password)
VALUES ('Charlie', 'Doe', 'charlie@example.com', 'AbcdefGH1234#');

SELECT email, password FROM users WHERE email = 'charlie@example.com'; -- doit afficher le hash SHA1

-- Erreur attendue (mdp trop court)
INSERT INTO users (firstname, lastname, email, password)
VALUES ('Eve', 'Bad', 'eve@example.com', 'weak');
```

- Utilisateurs : mise à jour sans changer le mot de passe (fournir l’ancien en clair pour le laisser inchangé)
```sql
-- Avant
SELECT id, email, password FROM users WHERE id = 1;

-- Inchangé : on repasse le même mot de passe en clair
UPDATE users
SET phone = '0700000000', password = 'P@$$w0rd#IUT'
WHERE id = 1;

-- Vérifie que le hash n’a pas bougé
SELECT id, password FROM users WHERE id = 1;
```

- Utilisateurs : mise à jour avec nouveau mot de passe + erreur
```sql
-- OK : nouveau mot de passe valide, sera re-haché
UPDATE users
SET password = 'NouveauMdpSecurise1#'
WHERE id = 1;

-- Erreur attendue : mot de passe avec espace
UPDATE users
SET password = 'Mot de passe'
WHERE id = 1;
```

### Articles

- Articles : insertion sans `stock_quantity` (doit retomber à 0 par défaut)
```sql
INSERT INTO articles (sku, title, unit_price, vat_rate)
VALUES ('SKU-0006', 'Wireless Mouse', 19.90, 20);

SELECT sku, stock_quantity FROM articles WHERE sku = 'SKU-0006';
```

- Stock_movements : insertion avec `article_id` et `change_quantity` (raison obligatoire car non NULL)
```sql
-- Approvisionner l’article 1 de +10 unités
INSERT INTO stock_movements (article_id, change_quantity, reason)
VALUES (1, 10, 'initial stock');

-- Contrôler les valeurs calculées et le stock mis à jour
SELECT id, before_qty, after_qty FROM stock_movements ORDER BY id DESC LIMIT 1;
SELECT id, stock_quantity FROM articles WHERE id = 1;
```

### Orders

- Orders : insertion avec status fourni (sera forcé à draft) + lignes + totaux
```sql
-- Créer une commande en demandant 'paid' : sera ramené à 'draft' par trg_orders_bi
INSERT INTO orders (user_id, status) VALUES (1, 'paid');
SELECT id, status FROM orders ORDER BY id DESC LIMIT 1; -- doit montrer 'draft'
SET @order_id := LAST_INSERT_ID();

-- Ajouter une ligne (totaux de la ligne et de la commande recalculés)
INSERT INTO order_lines (order_id, article_id, quantity)
VALUES (@order_id, 1, 2);

SELECT line_net, line_vat, line_incl_vat FROM order_lines WHERE order_id = @order_id;
SELECT total_net, total_vat, total_incl_vat FROM orders WHERE id = @order_id;
```

- Orders : passage à paid (mouvements négatifs) puis cancelled (mouvements positifs)
```sql
-- Passer la commande en 'confirmed' (obligatoire car draft -> paid est interdit)
UPDATE orders SET status = 'confirmed' WHERE id = @order_id;

-- Passer en 'paid' : insère des mouvements de stock en négatif
UPDATE orders SET status = 'paid' WHERE id = @order_id;

SELECT reason, change_quantity, before_qty, after_qty
FROM stock_movements
WHERE reason LIKE CONCAT('order ', @order_id, '%')
ORDER BY id DESC;

SELECT id, stock_quantity FROM articles WHERE id = 1; -- stock décrémenté

-- Annuler : mouvements en positif (restock)
UPDATE orders SET status = 'cancelled' WHERE id = @order_id;
SELECT change_quantity, after_qty FROM stock_movements
WHERE reason LIKE CONCAT('order ', @order_id, '%')
ORDER BY id DESC LIMIT 1;
SELECT stock_quantity FROM articles WHERE id = 1;
```

- Scénarios d’erreur supplémentaires
```sql
-- Stock insuffisant lors du passage en paid (quantité > stock dispo)
INSERT INTO orders (user_id) VALUES (1);
SET @order_id2 := LAST_INSERT_ID();
INSERT INTO order_lines (order_id, article_id, quantity) VALUES (@order_id2, 1, 9999);
UPDATE orders SET status = 'confirmed' WHERE id = @order_id2;
UPDATE orders SET status = 'paid' WHERE id = @order_id2; -- doit lever 'Stock insuffisant'

-- Mot de passe vide à la mise à jour
UPDATE users SET password = '' WHERE id = 1; -- doit lever l'erreur de complexité
```

## Possible corrections

- Générer le numéro de commande avec un compteur mensuel dédié (table séquence par mois)
