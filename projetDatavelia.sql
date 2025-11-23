CREATE DATABASE datavellia;
USE datavellia;

--Creer la table des roles : Cette table sera le livre des titres et honneurs.--
CREATE TABLE roles (
    idRole INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

--Creer la table des habitants : Cette table sera le registre royal des âmes de Datavellia.--
CREATE TABLE habitants (
    idHabitant INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) ,
    roleID INT,
    FOREIGN KEY (roleID) REFERENCES roles(id)
    );

--Inserer dans les tables--

--Inserer les rôles --

INSERT INTO roles (name) VALUES
('Chevaliers'), --Les chevaliers protègent les routes de données contre les attaques du chaos--
('Moines Archivistes'),--Les moines archivistes conservent les chroniques, veillant sur la pureté des infos--
('Artisans du code'),--Les artisans du code forgent des scripts et bâtissent des structures.--
('Bourgeois');--Et les bourgeois commercent, échangent, partagent des valeurs et des idées--

--Inserer les habitants --

INSERT INTO habitants (name, email, idRole) VALUES
('Chimère', 'chimere@datavellia.com', 1),
('Garuda', 'garuda@datavellia.com', 2),
('Griffon', 'griffon@datavellia.com', 3),
('Harpie', 'harpie@datavellia.com', 4);


--Afficher chaque habitant avec son rôle--
SELECT habitants.nom AS habitant,
 roles.nom AS role
 FROM habitants
JOIN roles ON habitants.role_id = roles.id;

--Corriger le lapsus du scribe--
UPDATE habitants
SET nom = 'Ménestrel du Code'
WHERE nom = 'Ménestrel du Codes';

--Creer la table des alliances--
CREATE TABLE alliances (
    idAlliance INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    roleID1 INT,
    roleID2 INT,
    FOREIGN KEY (roleID1) REFERENCES roles(id),
    FOREIGN KEY (roleID2) REFERENCES roles(id)
    CHECK (roleID1 != roleID2),
    CHECK (roleID1 < roleID2)
    );

--Creer la table des descendances--
CREATE TABLE descendances (
    idAlliance INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    allianceID INT,
    puissance_heritee DECIMAL(5,2),
    FOREIGN KEY (allianceID) REFERENCES alliances(idAlliance)
);

--Calculer la puissance moyenne des alliances --

CREATE FUNCTION puissanceMoyenneAlliance(alliance INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC --La fonction est déterministe car pour une même alliance, la puissance moyenne sera toujours la même.--
BEGIN
    DECLARE moyenne DECIMAL(5,2); --La variable pour stocker la moyenne.--

    --Nous calculons la moyenne des pouvoirs des habitants qui apparetiennent aux deuc roles de l'alliance--
    SELECT AVG(niveau_pouvoir) INTO moyenne
    FROM habitants
    WHERE roleID IN (
        SELECT roleID1 FROM alliances WHERE id = alliance
        UNION--On utilise l'union pour combiner les deux ensembles de rôles.--
        SELECT roleID2 FROM alliances WHERE id = alliance
    );

    RETURN moyenne; --Retourner la moyenne calculée.--

END;

--Créer une procédure pour créer une nouvelle descendance basée sur une alliance donnée--

CREATE PROCEDURE creerDescendance(
        IN nom_descendance VARCHAR(50),
        IN alliance INT
        )
BEGIN
    DECLARE moyenne DECIMAL(5,2);-- Variable pour stocker la moyenne
    SET moyenne = puissanceMoyenneAlliance(alliance);-- On calcule la moyenne

    -- On insère une nouvelle descendance avec la puissance heritée--
    INSERT INTO descendances (name, allianceID, puissance_heritee)
    VALUES (nom_descendance, alliance, moyenne);

END;


GRANT SELECT ON *.* TO 'moines'@'localhost';                 -- Les moines peuvent lire
GRANT INSERT ON habitants TO 'artisans'@'localhost';         -- Les artisans peuvent insérer
GRANT UPDATE ON alliances TO 'chevaliers'@'localhost';       -- Les chevaliers peuvent mettre à jour
GRANT ALL PRIVILEGES ON datavellia.* TO 'roi'@'localhost';   -- Le roi peut tout faire

--Créer une table pour journaliser les événements importants--
CREATE TABLE iF NOT EXISTS journalDesEvenements (
    id INT AUTO_INCREMENT PRIMARY KEY,             -- Identifiant de l'événement
    evenement VARCHAR(255),                        -- Description de l'événement
    date_evenement DATETIME DEFAULT CURRENT_TIMESTAMP  -- Date et heure automatiques
);

--Créer un trigger pour journaliser la création d'une nouvelle alliance--
CREATE TRIGGER log_alliance_creation
AFTER INSERT ON alliances
FOR EACH ROW
BEGIN
    INSERT INTO journalDesEvenements (evenement)
    VALUES (CONCAT('Nouvelle alliance créée : ', NEW.nom));  -- Ajout automatique
END;


--Chapitre III--

-- Exercice I : Le Miroir des Titres

-- 1️) Ajouter une nouvelle colonne "niveau_honneur" dans la table roles
ALTER TABLE roles
ADD niveau_honneur INT;

-- 2️) Vérifier la table
SELECT * FROM roles;

-- 3️) Mettre à jour chaque rôle avec un niveau d’honneur selon sa gloire
UPDATE roles SET niveau_honneur = 10 WHERE name = 'Chevaliers';
UPDATE roles SET niveau_honneur = 8 WHERE name = 'Moines Archivistes';
UPDATE roles SET niveau_honneur = 7 WHERE name = 'Artisans du code';
UPDATE roles SET niveau_honneur = 5 WHERE name = 'Bourgeois';

-- 4️) Afficher les rôles triés par honneur décroissant
SELECT * FROM roles
ORDER BY niveau_honneur DESC;

-- Exercice II : Les Doubles Liens des Maisons

-- Requête pour relier habitants → rôles → alliances
SELECT 
    h.name AS habitant,
    r.name AS role,
    a.name AS alliance
FROM habitants h
JOIN roles r ON h.roleID = r.id
LEFT JOIN alliances a 
    ON r.id = a.roleID1 OR r.id = a.roleID2;


-- Exercice III : Les Héritiers des Héritiers

-- 1️ ) Créer une vue affichant les descendants, leur alliance et leur puissance héritée
CREATE OR REPLACE VIEW vue_lignee_royale AS
SELECT 
    d.name AS descendant,
    a.name AS alliance_origine,
    d.puissance_heritee,
    AVG(d.puissance_heritee) OVER (PARTITION BY a.id) AS puissance_moyenne_alliance
FROM descendances d
JOIN alliances a ON d.allianceID = a.id;

-- 2️ ) Afficher la vue
SELECT * FROM vue_lignee_royale;

-- Exercice IV : Le miroir des instructions 

-- 1) Creer une table pour gerer les intrusions 
CREATE TABLE INTRUSIONS ( 
    id INT AUTO_INCREMENT PRIMARY KEY, 
    utilisateur VARCHAR(100),
    action VARCHAR(255),
    dateEvenement DATETIME DEFAULT CURRENT_TIMESTAMP,
    gravite ENUM('faible', 'moyenne', 'haute') DEFAULT 'faible'
);

-- 2) Creer un trigger pour journaliser les tentatives d'intrusions
CREATE TRIGGER log_intrusion
AFTER INSERT ON journalDesEvenements
FOR EACH ROW
BEGIN
    IF NEW.evenement LIKE '%erreur%' OR NEW.evenement LIKE '%connexion%' THEN
        INSERT INTO intrusions (utilisateur, action, gravite)
        VALUES ('inconnu', NEW.evenement, 'haute'); 
    END IF;
END;

-- 3) Créer une vue listant les 5 dernières intrusions
CREATE OR REPLACE VIEW vue_dernieres_intrusions AS
SELECT *
FROM intrusions
ORDER BY date_evenement DESC
LIMIT 5;

-- 4) Afficher la vue
INSERT INTO journalDesEvenements (evenement) VALUES ('Tentative de connexion refusée');
INSERT INTO journalDesEvenements (evenement) VALUES ('Erreur critique détectée');
INSERT INTO journalDesEvenements (evenement) VALUES ('Nouvelle alliance créée : Ordre des Architectes');


-- EXERCICE V : Les Portails du Réseau

CREATE TABLE pare_feu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    adresseIP VARCHAR(45),
    regle ENUM('autoriser', 'bloquer') NOT NULL,
    description VARCHAR(255),
    date_ajout DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2️)Insérer des règles d’autorisation et de blocage
INSERT INTO pare_feu (adresse_ip, regle, description) VALUES
('192.168.1.10', 'autoriser', 'Serveur interne'),
('192.168.1.55', 'bloquer', 'Adresse suspecte détectée'),
('10.0.0.7', 'bloquer', 'Tentative d’accès non autorisée'),
('172.16.0.3', 'autoriser', 'Terminal de confiance');

-- 3️) Creer une vue affichant uniquement les connexions bloquees
CREATE OR REPLACE VIEW vue_connexions_bloquees AS
SELECT adresse_ip, description, date_ajout
FROM pare_feu
WHERE regle = 'bloquer';

-- 4️ ) Créer une fonction pour ajouter automatiquement une règle au pare-feu
CREATE FUNCTION ajouter_regle(ip VARCHAR(45), action ENUM('autoriser', 'bloquer'), desc_text VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    INSERT INTO pare_feu (adresse_ip, regle, description)
    VALUES (ip, action, desc_text);
    RETURN CONCAT('Règle ajoutée pour : ', ip, ' → ', action);
END
