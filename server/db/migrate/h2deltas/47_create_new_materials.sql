--****
-- Copyright 2014 ThoughtWorks, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--*****

-- fixing bad data
--unsetting unnecessary fields based on material type
UPDATE materials SET url=null, username=null, password=null, checkexternals=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type='DependencyMaterial';
UPDATE materials SET username=null, password=null, checkexternals=null, pipelineName=null, stageName=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type='HgMaterial';
UPDATE materials SET username=null, password=null, checkexternals=null, pipelineName=null, stageName=null, view=null, usetickets=null WHERE type='GitMaterial';
UPDATE materials SET pipelineName=null, stageName=null, view=null, branch=null, submodulefolder=null, usetickets=null WHERE type='SvnMaterial';
UPDATE materials SET checkexternals=null, pipelineName=null, stageName=null, branch=null, submodulefolder=null WHERE type='P4Material';

--unsetting '' values
UPDATE materials SET url=null WHERE TRIM(url)='';
UPDATE materials SET username=null WHERE TRIM(username)='';
UPDATE materials SET password=null WHERE TRIM(password)='';
UPDATE materials SET folder=null WHERE TRIM(folder)='';
UPDATE materials SET pipelineName=null WHERE TRIM(pipelineName)='';
UPDATE materials SET stageName=null WHERE TRIM(stageName)='';
UPDATE materials SET name=null WHERE TRIM(name)='';
UPDATE materials SET view=null WHERE TRIM(view)='';
UPDATE materials SET branch=null WHERE TRIM(branch)='';
UPDATE materials SET submoduleFolder=null WHERE TRIM(submoduleFolder)='';
UPDATE materials SET useTickets=null WHERE TRIM(useTickets)='';

-- create table
CREATE TABLE newMaterials (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY (START WITH 1) PRIMARY KEY,
    type VARCHAR(255),
    url TEXT,
    username VARCHAR(255),
    password VARCHAR(255),
    checkexternals BOOLEAN DEFAULT FALSE,
    pipelinename VARCHAR(255),
    stagename VARCHAR(255),
    view TEXT,
    branch TEXT,
    submodulefolder TEXT,
    usetickets VARCHAR(10),
    fingerprint CHAR(64)
);

INSERT INTO newMaterials(type, url, username, password, checkexternals, pipelineName, stageName, view, branch, submoduleFolder, useTickets)
  SELECT DISTINCT type, url, username, '', checkexternals, pipelineName, stageName, view, branch, submoduleFolder, useTickets FROM materials;

-- choose the latest password for each material to avoid duplicating materials
UPDATE newmaterials A SET password =
  (SELECT password FROM materials WHERE id =
    ( SELECT max(B.id)
      FROM  materials B
      WHERE (A.type=B.type OR (A.type IS NULL AND B.type IS NULL)) AND
            (A.url=B.url OR (A.url IS NULL AND B.url IS NULL)) AND
            (A.username=B.username OR (A.username IS NULL AND B.username IS NULL)) AND
            (A.checkexternals=B.checkexternals  OR (A.checkexternals IS NULL AND B.checkexternals IS NULL)) AND
            (A.pipelineName=B.pipelineName  OR (A.pipelineName IS NULL AND B.pipelineName IS NULL)) AND
            (A.stageName=B.stageName  OR (A.stageName IS NULL AND B.stageName IS NULL)) AND
            (A.view=B.view  OR (A.view IS NULL AND B.view IS NULL)) AND
            (A.branch=B.branch  OR (A.branch IS NULL AND B.branch  IS NULL)) AND
            (A.submoduleFolder=B.submoduleFolder  OR (A.submoduleFolder IS NULL AND B.submoduleFolder IS NULL)) AND
            (A.useTickets=B.useTickets OR (A.useTickets IS NULL AND B.useTickets IS NULL))
      GROUP BY B.type, B.url, B.username, B.checkexternals, B.pipelineName, B.stageName, B.view, B.branch, B.submoduleFolder, B.useTickets
    )
  );

SET @delimiter = '<|>';

UPDATE newMaterials SET fingerprint =
  CASE type
      WHEN 'DependencyMaterial'
        THEN HASH('SHA256', STRINGTOUTF8(concat('type=', type, @delimiter, 'pipelineName=', pipelineName, @delimiter, 'stageName=', stageName) ), 1)
      WHEN 'HgMaterial'
        THEN HASH('SHA256', STRINGTOUTF8(concat('type=', type, @delimiter, 'url=', url) ), 1)
      WHEN 'GitMaterial'
        THEN HASH('SHA256', STRINGTOUTF8(concat('type=', type, @delimiter, 'url=', url, @delimiter, 'branch=', branch) ), 1)
      WHEN 'SvnMaterial'
        THEN HASH('SHA256', STRINGTOUTF8(concat('type=', type, @delimiter, 'url=', url, @delimiter, 'username=', username, @delimiter, 'checkExternals=', checkExternals) ), 1)
      WHEN 'P4Material'
        THEN HASH('SHA256', STRINGTOUTF8(concat('type=', type, @delimiter, 'url=', url, @delimiter, 'username=', username, @delimiter, 'view=', view) ), 1)
    END;

-- point material to newMaterial
ALTER TABLE materials ADD COLUMN newMaterialId BIGINT;

UPDATE materials m SET newMaterialId =
  (
    SELECT n.id
    FROM newMaterials n
    WHERE ((m.type IS NULL AND n.type IS NULL) OR (m.type = n.type))
      AND ((m.url IS NULL AND n.url IS NULL) OR (m.url = n.url))
      AND ((m.username IS NULL AND n.username IS NULL) OR (m.username = n.username))
      AND ((m.checkexternals IS NULL AND n.checkexternals IS NULL) OR (m.checkexternals = n.checkexternals))
      AND ((m.pipelineName IS NULL AND n.pipelineName IS NULL) OR (m.pipelineName = n.pipelineName))
      AND ((m.stageName IS NULL AND n.stageName IS NULL) OR (m.stageName = n.stageName))
      AND ((m.view IS NULL AND n.view IS NULL) OR (m.view = n.view))
      AND ((m.branch IS NULL AND n.branch IS NULL) OR (m.branch = n.branch))
      AND ((m.submoduleFolder IS NULL AND n.submoduleFolder IS NULL) OR (m.submoduleFolder = n.submoduleFolder))
      AND ((m.useTickets IS NULL AND n.useTickets IS NULL) OR (m.useTickets = n.useTickets))
  );

-- point modifications to newMaterials
ALTER TABLE modifications ADD COLUMN newMaterialId BIGINT;

UPDATE modifications set newMaterialId = (SELECT newMaterialId FROM materials WHERE materials.id = modifications.materialId);

CREATE SEQUENCE seq_ordered_modifications START WITH 1;

CREATE TABLE ordered_modifications AS
  SELECT NEXT VALUE FOR seq_ordered_modifications newModificationId, *
    FROM (
      SELECT mo.*
      FROM modifications mo
        INNER JOIN materials ma ON mo.materialid = ma.id
      ORDER BY ma.id ASC, mo.id DESC);

CREATE INDEX idx_ordered_mods_id ON ordered_modifications(id);
CREATE INDEX idx_ordered_mods_newMaterialId ON ordered_modifications(newMaterialId);
CREATE INDEX idx_ordered_mods_materialId ON ordered_modifications(materialId);
CREATE INDEX idx_ordered_mods_newModificationId ON ordered_modifications(newModificationId);


-- Delete duplicate modifications
CREATE TABLE unique_modifications AS
  SELECT newMaterialId, revision, MIN(newModificationId) AS realModificationId
    FROM ordered_modifications
  GROUP BY newMaterialid, revision;


CREATE INDEX idx_unique_mods_newMaterialId_revisions ON unique_modifications(newMaterialId, revision);
CREATE INDEX idx_unique_mods_id ON unique_modifications(realModificationId);

CREATE TABLE unique_modifications_with_all_columns AS
  SELECT om.*
  FROM unique_modifications um
    INNER JOIN ordered_modifications om ON om.newModificationId = um.realModificationId;

-- sanity check to ensure we have unique newModificationIds
ALTER TABLE unique_modifications_with_all_columns ADD CONSTRAINT unq_newModiId UNIQUE (newModificationId);


-- add the new PipelineMaterialRevisions table
CREATE TABLE PipelineMaterialRevisions (
   id BIGINT GENERATED BY DEFAULT AS IDENTITY (START WITH 1) PRIMARY KEY,
   folder VARCHAR(255),
   name VARCHAR(255),
   pipelineId BIGINT NOT NULL,
   toRevisionId BIGINT NOT NULL,
   fromRevisionId BIGINT NOT NULL,
   changed BOOLEAN DEFAULT FALSE
);

-- set newModificationId on ordered_modifications so we can use it to create PMRs
UPDATE ordered_modifications om SET newModificationId =
  SELECT realModificationId
  FROM unique_modifications um
  WHERE um.newMaterialId = om.newMaterialId
    AND um.revision = om.revision;

--- helper indexes to speed up next insert
CREATE INDEX idx_new_material_id ON materials(newMaterialId);
CREATE INDEX idx_mod_new_material_id ON modifications(newMaterialId);

INSERT INTO PipelineMaterialRevisions(name, folder, pipelineId, fromRevisionId, toRevisionId, changed)
  SELECT name, folder, pipelineId,
          (SELECT newModificationId FROM ordered_modifications WHERE id = (SELECT MAX(id) FROM ordered_modifications om WHERE om.materialId = m.id)),
          (SELECT newModificationId FROM ordered_modifications WHERE id = (SELECT MIN(id) FROM ordered_modifications om WHERE om.materialId = m.id)),
          (SELECT changed FROM ordered_modifications om WHERE om.materialId = m.id LIMIT 1)
  FROM materials m;

CREATE INDEX idx_pmr_pipeline_id ON pipelineMaterialRevisions (pipelineId);

-- Fix modifications
ALTER TABLE modifiedFiles DROP CONSTRAINT FK_MODIFIEDFILES_MODIFICATIONS;
DELETE FROM modifications;

ALTER TABLE modifications ADD COLUMN newModificationId BIGINT;
ALTER TABLE modifications DROP COLUMN changed;

INSERT INTO modifications
  (id, type, username, comment, emailAddress, revision, modifiedTime, fromExternal, materialId, newMaterialId, newModificationId)
  SELECT id, type, username, comment, emailAddress, revision, modifiedTime, fromExternal, materialId, newMaterialId, newModificationId
    FROM unique_modifications_with_all_columns;

-- Fix modifiedFiles reference to modification.id
ALTER TABLE modifiedFiles ADD COLUMN newModificationId BIGINT;



UPDATE modifiedFiles mf SET newModificationId = (
  SELECT newModificationId
  FROM modifications mod
  WHERE mod.id = mf.modificationId);

DELETE FROM modifiedFiles WHERE newModificationId IS NULL;
UPDATE modifiedFiles SET modificationId = newModificationId;
ALTER TABLE modifiedFiles DROP COLUMN newModificationId;

-- Fix modification.id to be the new id
UPDATE modifications SET id = newModificationId;
ALTER TABLE modifications DROP COLUMN newModificationId;
ALTER TABLE modifiedFiles ADD CONSTRAINT FK_MODIFIEDFILES_MODIFICATIONS FOREIGN KEY (modificationId) REFERENCES modifications(id) ON DELETE CASCADE;

DROP TABLE unique_modifications_with_all_columns;
DROP TABLE unique_modifications;
DROP TABLE ordered_modifications;
DROP SEQUENCE seq_ordered_modifications;


-- Removing the following foreign-keys because hibernate AND ibatis use different connections AND therefore different transactions,
-- resulting in tests failing to see referenced objects, e.g. Pipeline is saved but not committed AND trying to save PMR bombs
--ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_pipeline_id FOREIGN KEY (pipelineId) REFERENCES pipelines (id);
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_from_revision FOREIGN KEY (fromRevisionId) REFERENCES modifications (id);
ALTER TABLE pipelineMaterialRevisions ADD CONSTRAINT fk_pmr_to_revision FOREIGN KEY (toRevisionId) REFERENCES modifications (id);


-- Rename newMaterials to materials
ALTER TABLE modifications DROP CONSTRAINT fk_modifications_materials;
ALTER TABLE modifications DROP COLUMN materialId;
DROP TABLE materials;

ALTER TABLE newMaterials RENAME TO materials;

--ALTER TABLE modifications ADD CONSTRAINT fk_modifications_materials FOREIGN KEY (newMaterialId) REFERENCES materials(id);

-- Rename newMaterialId
ALTER TABLE modifications ALTER COLUMN newMaterialId RENAME TO materialId;

-- Make fingerprint unique AND not null
ALTER TABLE materials ALTER COLUMN fingerprint SET NOT NULL;
ALTER TABLE materials ADD CONSTRAINT unique_fingerprint UNIQUE (fingerprint);


--//@UNDO

-- we don't support undo for this
