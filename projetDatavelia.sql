CREATE DATABASE datavellia;
USE datavellia;

--Creer la table des roles : Cette table sera le livre des titres et honneurs.--
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

--Creer la table des habitants : Cette table sera le registre royal des âmes de Datavellia.--
CREATE TABLE habitants (
    id INT AUTO_INCREMENT PRIMARY KEY,
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

INSERT INTO habitants (name, email, roleID) VALUES
('Aldric', 'aldric@datavellia.com', 1),
('Lyra', 'lyra@datavellia.com', 2),
('Thom', 'thom@datavellia.com', 3),
('Elena', 'elena@datavellia.com', 4);


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
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    roleID1 INT,
    roleID2 INT,
    FOREIGN KEY (roleID1) REFERENCES roles(id),
    FOREIGN KEY (roleID2) REFERENCES roles(id)
    );

--Creer la table des descendances--
CREATE TABLE descendances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    allianceID INT,
    puissance_heritee DECIMAL(5,2),
    FOREIGN KEY (allianceID) REFERENCES alliances(id)
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

