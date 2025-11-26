CREATE DATABASE datavellia;
USE datavellia;

--Creer la table des roles : Cette table sera le livre des titres et honneurs.--
CREATE TABLE roles (
    idRole INT AUTO_INCREMENT PRIMARY KEY,
    nomRole VARCHAR(100) NOT NULL
);

--Creer la table des habitants : Cette table sera le registre royal des âmes de Datavellia.--
CREATE TABLE habitants (
    idHabitant INT AUTO_INCREMENT PRIMARY KEY,
    nomHabitant VARCHAR(100) NOT NULL,
    emailHabitant VARCHAR(150) UNIQUE NOT NULL,
    idRole INT,
    FOREIGN KEY (idRole) REFERENCES roles(idRole)
);

--Inserer les rôles --
INSERT INTO roles (nomRole) VALUES
('Chevaliers'),
('Moines Archivistes'),
('Artisans du code'),
('Bourgeois');

--Inserer les habitants --
INSERT INTO habitants (nomHabitant, emailHabitant, idRole) VALUES
('Chimère', 'chimere@datavellia.com', 1),
('Garuda', 'garuda@datavellia.com', 2),
('Griffon', 'griffon@datavellia.com', 3),
('Harpie', 'harpie@datavellia.com', 4);

--Afficher chaque habitant avec son rôle--
SELECT 
    hab.idHabitant,
    hab.nomHabitant,
    hab.emailHabitant,
    r.nomRole
FROM habitants AS hab
JOIN roles AS r ON hab.idRole = r.idRole;

--Corriger le lapsus du scribe--
UPDATE roles
SET nomRole = 'Ménestrel du Code'
WHERE nomRole = 'Menestrel du Codes';

--Chapitre I Extension--

--1--
CREATE TABLE guildes (
    idGuilde INT AUTO_INCREMENT PRIMARY KEY,
    nomGuilde VARCHAR(100) NOT NULL,
    descriptionGuilde VARCHAR(255),
    dateCreation DATE DEFAULT CURRENT_DATE,
    siegeSocial VARCHAR(200)
);

ALTER TABLE habitants
ADD idGuilde INT NULL,
ADD niveauPouvoir INT DEFAULT 1 CHECK (niveauPouvoir BETWEEN 1 AND 100),
ADD FOREIGN KEY (idGuilde) REFERENCES guildes(idGuilde);

--2--
CREATE TABLE roles_guildes (
    idRole INT NOT NULL,
    idGuilde INT NOT NULL,
    dateAffiliation DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (idRole, idGuilde),
    FOREIGN KEY (idRole) REFERENCES roles(idRole) ON DELETE CASCADE,
    FOREIGN KEY (idGuilde) REFERENCES guildes(idGuilde) ON DELETE CASCADE
);

INSERT INTO guildes (nomGuilde, descriptionGuilde, siegeSocial) VALUES
('Guilde des Lames', 'Chevaliers valeureux, défenseurs du royaume', 'Château d’Albion'),
('Guilde des Archives', 'Moines érudits, gardiens du savoir', 'Monastère de Fondcombe'),
('Forge Numérique', 'Artisans du code et bâtisseurs de scripts', 'Montagnes de Moria'),
('Compagnie Dorée', 'Marchands de valeurs et négociants', 'Port de Dorwinion');

--3--
UPDATE habitants SET idGuilde = 1, niveauPouvoir = 85 WHERE nomHabitant = 'Chimère';
UPDATE habitants SET idGuilde = 2, niveauPouvoir = 65 WHERE nomHabitant = 'Garuda';
UPDATE habitants SET idGuilde = 3, niveauPouvoir = 75 WHERE nomHabitant = 'Griffon';
UPDATE habitants SET idGuilde = 4, niveauPouvoir = 60 WHERE nomHabitant = 'Harpie';

INSERT INTO roles_guildes (idRole, idGuilde) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4);

SELECT  
    hab.nomHabitant,
    hab.emailHabitant,
    r.nomRole,
    gld.nomGuilde,
    hab.niveauPouvoir
FROM habitants AS hab
JOIN roles AS r ON hab.idRole = r.idRole
LEFT JOIN guildes AS gld ON hab.idGuilde = gld.idGuilde
ORDER BY hab.niveauPouvoir DESC;

--Chapitre II--

--Creer la table des alliances--
CREATE TABLE alliances (
    idAlliance INT AUTO_INCREMENT PRIMARY KEY,
    nomAlliance VARCHAR(100) NOT NULL,
    roleID1 INT NOT NULL,
    roleID2 INT NOT NULL,
    FOREIGN KEY (roleID1) REFERENCES roles(idRole),
    FOREIGN KEY (roleID2) REFERENCES roles(idRole),
    CHECK (roleID1 != roleID2),
    CHECK (roleID1 < roleID2)
);

--Creer la table des descendances--
CREATE TABLE descendance (
    idDescendant INT AUTO_INCREMENT PRIMARY KEY,
    nomDescendant VARCHAR(100) NOT NULL,
    idAlliance INT NOT NULL,
    niveauPuissanceHeritee INT,
    dateNaissance DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (idAlliance) REFERENCES alliances(idAlliance)
);

INSERT INTO alliances (nomAlliance, roleID1, roleID2) VALUES
('Ordre des Architectes Spirituels', 2, 3),
('Pacte des Lames Marchandes', 1, 4),
('Alliance de la Terre Sacrée', 2, 4),
('Confrérie des Forgerons Guerriers', 1, 3),
('Guilde des Commerçants Ruraux', 4, 3);

--Calculer la puissance moyenne des alliances--

DELIMITER //
CREATE FUNCTION puissanceMoyenneAlliance(p_idAlliance INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE moyenne DECIMAL(5,2);

    SELECT AVG(hab.niveauPouvoir)
    INTO moyenne
    FROM habitants hab
    JOIN alliances a ON a.idAlliance = p_idAlliance
    WHERE hab.idRole IN (a.roleID1, a.roleID2);

    RETURN moyenne;
END //
DELIMITER ;

--Créer une procédure pour créer une nouvelle descendance basée sur une alliance donnée--
DELIMITER //
CREATE PROCEDURE creerDescendant (
    IN p_nomDescendant VARCHAR(100),
    IN p_idAlliance INT
)
BEGIN
    DECLARE puissanceHeritee DECIMAL(5,2);
    SET puissanceHeritee = puissanceMoyenneAlliance(p_idAlliance);

    INSERT INTO descendance (nomDescendant, idAlliance, niveauPuissanceHeritee)
    VALUES (p_nomDescendant, p_idAlliance, puissanceHeritee);
END //
DELIMITER ;

-- Moines archivistes : lecture uniquement
GRANT SELECT ON habitants, roles, guildes, alliances, descendance TO moines_archivistes;

-- Artisans : peuvent ajouter des habitants
GRANT INSERT ON habitants TO artisans_code;

-- Chevaliers : peuvent modifier les alliances
GRANT UPDATE ON alliances TO chevaliers;

-- Roi : pouvoir absolu
GRANT ALL PRIVILEGES ON *.* TO to_i_student WITH GRANT OPTION;

--Créer une table pour journaliser les événements importants--
CREATE TABLE journalEvenements (
    idEvenement INT AUTO_INCREMENT PRIMARY KEY,
    typeEvenement VARCHAR(50),
    detailsEvenement VARCHAR(255),
    dateEvenement TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Créer un trigger pour journaliser la création d'une nouvelle alliance--
DELIMITER //
CREATE TRIGGER logNouvelleAlliance
AFTER INSERT ON alliances
FOR EACH ROW
BEGIN
    INSERT INTO journalEvenements (typeEvenement, detailsEvenement)
    VALUES ('Alliance créée', CONCAT('Alliance : ', NEW.nomAlliance));
END //
DELIMITER ;

--Créer un trigger pour journaliser la naissance d'un nouveau descendant--
DELIMITER //
CREATE TRIGGER logNouvelleNaissance
AFTER INSERT ON descendance
FOR EACH ROW
BEGIN
    INSERT INTO journalEvenements (typeEvenement, detailsEvenement)
    VALUES ('Naissance', CONCAT('Descendant : ', NEW.nomDescendant));
END //
DELIMITER ;

--Créer une vue pour afficher les chroniques des descendants avec leur alliance et puissance héritée--
CREATE OR REPLACE VIEW chroniques_du_royaume AS
SELECT 
    dsc.nomDescendant,
    a.nomAlliance,
    dsc.niveauPuissanceHeritee,
    dsc.dateNaissance
FROM descendance dsc
JOIN alliances a ON dsc.idAlliance = a.idAlliance;

--Chapitre III--

-- Exercice I : Le Miroir des Titres

ALTER TABLE roles
ADD COLUMN niveauHonneur INT DEFAULT 0;

SELECT * FROM roles;

UPDATE roles
SET nomRole = 
    CASE
        WHEN nomRole = 'Chevaliers' THEN 'Chevalier'
        WHEN nomRole = 'Moines Archivistes' THEN 'Moine Archiviste'
        WHEN nomRole = 'Artisans du code' THEN 'Artisan du code'
        WHEN nomRole = 'Bourgeois' THEN 'Bourgeois'
    END;

UPDATE roles SET niveauHonneur = 10 WHERE nomRole = 'Chevalier';
UPDATE roles SET niveauHonneur = 8 WHERE nomRole = 'Moine Archiviste';
UPDATE roles SET niveauHonneur = 7 WHERE nomRole = 'Artisan du code';
UPDATE roles SET niveauHonneur = 5 WHERE nomRole = 'Bourgeois';

SELECT * FROM roles
ORDER BY niveauHonneur DESC;

-- Exercice II : Les Doubles Liens des Maisons
SELECT
    hab.nomHabitant,
    hab.emailHabitant,
    r.nomRole,
    a.nomAlliance
FROM habitants AS hab
JOIN roles AS r ON hab.idRole = r.idRole
LEFT JOIN alliances AS a ON (r.idRole = a.roleID1 OR r.idRole = a.roleID2)
ORDER BY hab.nomHabitant;

-- Exercice III : Les Héritiers des Héritiers
CREATE OR REPLACE VIEW vue_lignee_royale AS
SELECT 
    dsc.nomDescendant AS descendant,
    a.nomAlliance AS allianceOrigine,
    dsc.niveauPuissanceHeritee,
    AVG(dsc.niveauPuissanceHeritee) OVER (PARTITION BY a.idAlliance) AS puissanceMoyenneAlliance
FROM descendance dsc
JOIN alliances a ON dsc.idAlliance = a.idAlliance;

SELECT * FROM vue_lignee_royale;

-- Exercice IV : Intrusions
CREATE TABLE journalIntrusions (
    idIntrusion INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur VARCHAR(100),
    actionSuspecte VARCHAR(255),
    graviteIntrusion INT CHECK (graviteIntrusion BETWEEN 1 AND 10),
    dateIntrusion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER log_intrusion
BEFORE DELETE ON roles
FOR EACH ROW
BEGIN
    INSERT INTO journalIntrusions (utilisateur, actionSuspecte, graviteIntrusion)
    VALUES (CURRENT_USER(), 'Tentative de suppression sur roles', 9);
END //
DELIMITER ;

CREATE OR REPLACE VIEW vue_intrusions_recente AS
SELECT 
    utilisateur,
    actionSuspecte,
    graviteIntrusion,
    dateIntrusion
FROM journalIntrusions
ORDER BY dateIntrusion DESC
LIMIT 5;

SELECT * FROM vue_intrusions_recente;

-- EXERCICE V : LES PORTAILS DU RÉSEAU (FULL MAJUSCULE)
CREATE TABLE PARE_FEU (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    ADRESSE_IP VARCHAR(45),
    REGLE ENUM('AUTORISER', 'BLOQUER') NOT NULL,
    DESCRIPTION VARCHAR(255),
    DATE_AJOUT DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO PARE_FEU (ADRESSE_IP, REGLE, DESCRIPTION) VALUES
('192.168.1.10', 'AUTORISER', 'SERVEUR INTERNE'),
('192.168.1.55', 'BLOQUER', 'ADRESSE SUSPECTE DÉTECTÉE'),
('10.0.0.7', 'BLOQUER', 'TENTATIVE D''ACCÈS NON AUTORISÉE'),
('172.16.0.3', 'AUTORISER', 'TERMINAL DE CONFIANCE');

CREATE OR REPLACE VIEW VUE_CONNEXIONS_BLOQUEES AS
SELECT ADRESSE_IP, DESCRIPTION, DATE_AJOUT
FROM PARE_FEU
WHERE REGLE = 'BLOQUER';

DELIMITER //
CREATE PROCEDURE AJOUTER_REGLE (
    IN P_ADRESSE_IP VARCHAR(45),
    IN P_REGLE VARCHAR(10),
    IN P_DESCRIPTION VARCHAR(255)
)
BEGIN
    INSERT INTO PARE_FEU (ADRESSE_IP, REGLE, DESCRIPTION)
    VALUES (P_ADRESSE_IP, UPPER(P_REGLE), UPPER(P_DESCRIPTION));
END //
DELIMITER ;

CALL AJOUTER_REGLE('203.0.113.99', 'bloquer', 'INTRUSION SUSPECTE');

-- EXERCICE VI – LE SCEAU ROYAL (CHIFFREMENT ET SIGNATURE)

CREATE TABLE messagesRoyaux (
    idMessage INT AUTO_INCREMENT PRIMARY KEY,
    auteur VARCHAR(100) NOT NULL,
    messageChiffre VARBINARY(500) NOT NULL,
    signatureMessage VARBINARY(500),
    dateMessage TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET @cleRoyale = 'SECRETCLEF123';

INSERT INTO messagesRoyaux (auteur, messageChiffre, signatureMessage)
VALUES 
('Roi Louis',
    AES_ENCRYPT('Protégez la frontière Nord, les orcs approchent.', @cleRoyale),
    MD5('Protégez la frontière Nord, les orcs approchent.')
),
('Roi Louis',
    AES_ENCRYPT('Convocation du Conseil Royal demain à l’aube.', @cleRoyale),
    MD5('Convocation du Conseil Royal demain à l’aube.')
);

CREATE OR REPLACE VIEW vueMessagesDechiffres AS
SELECT 
    idMessage,
    auteur,
    AES_DECRYPT(messageChiffre, @cleRoyale) AS messageLisible,
    signatureMessage,
    dateMessage
FROM messagesRoyaux;

SELECT * FROM vueMessagesDechiffres;

SELECT 
    idMessage,
    auteur,
    AES_DECRYPT(messageChiffre, @cleRoyale) AS messageLisible,
    IF(MD5(AES_DECRYPT(messageChiffre, @cleRoyale)) = signatureMessage, 'Authentique', 'Falsifié')
    AS statutAuthenticite,
    dateMessage
FROM messagesRoyaux;
