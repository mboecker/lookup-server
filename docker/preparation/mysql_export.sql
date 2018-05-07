-- Create temporary database
DROP DATABASE IF EXISTS openml_exporting;
CREATE DATABASE openml_exporting;

-- Copy table structures
CREATE TABLE openml_exporting.run LIKE openml.run;
CREATE TABLE openml_exporting.input LIKE openml.input;
CREATE TABLE openml_exporting.input_setting LIKE openml.input_setting;
CREATE TABLE openml_exporting.evaluation LIKE openml.evaluation;
CREATE TABLE openml_exporting.implementation LIKE openml.implementation;

-- Remove unnecessary columns
ALTER TABLE openml_exporting.run
  DROP COLUMN uploader,
  DROP COLUMN start_time,
  DROP COLUMN error_message,
  DROP COLUMN run_details,
  DROP COLUMN visibility;
  
ALTER TABLE openml_exporting.input
  DROP COLUMN description,
  DROP COLUMN dataType,
  DROP COLUMN defaultValue,
  DROP COLUMN recommendedRange;
  
ALTER TABLE openml_exporting.input_setting
  DROP COLUMN input;

ALTER TABLE openml_exporting.evaluation
  DROP COLUMN evaluation_engine_id,
  DROP COLUMN array_data;
  
ALTER TABLE openml_exporting.implementation
  DROP COLUMN uploader,
  DROP COLUMN custom_name,
  DROP COLUMN class_name,
  DROP COLUMN version,
  DROP COLUMN external_version,
  DROP COLUMN creator,
  DROP COLUMN contributor,
  DROP COLUMN uploadDate,
  DROP COLUMN licence,
  DROP COLUMN language,
  DROP COLUMN description,
  DROP COLUMN fullDescription,
  DROP COLUMN installationNotes,
  DROP COLUMN dependencies,
  DROP COLUMN implements,
  DROP COLUMN binary_file_id,
  DROP COLUMN source_file_id,
  DROP COLUMN visibility,
  DROP COLUMN citation;	

-- Copy only runs from our upload, and for multiple runs use only the latest run. Also remove runs without evaluations.
INSERT INTO openml_exporting.run
  SELECT r1.rid, r1.setup, r1.task_id
  FROM run AS r1
  WHERE r1.start_time = (SELECT MAX(r2.start_time) FROM run AS r2 WHERE r2.setup = r1.setup AND r2.task_id = r1.task_id)
    AND r1.rid IN (SELECT source FROM evaluation)
    AND uploader = 2702;

-- Copy only parameter values for the runs in run
INSERT IGNORE INTO openml_exporting.input_setting
  SELECT input_setting.setup, input_id, value
  FROM openml.input_setting, openml_exporting.run
  WHERE input_setting.setup = run.setup;

-- Copy only parameter definitions for the values in input_setting
INSERT IGNORE INTO openml_exporting.input
  SELECT id, fullName, implementation_id, name
  FROM openml.input
  JOIN openml_exporting.input_setting
  ON input.id = input_setting.input_id;

-- Copy only run results for the runs in run
INSERT INTO openml_exporting.evaluation
  SELECT source, function_id, value, stdev
  FROM openml.evaluation, openml_exporting.run
  WHERE evaluation.source = run.rid
  AND function_id IN (4,45,54,59,63);
  
-- Copy only implementation details for the implementations referenced in input
INSERT INTO openml_exporting.implementation
  SELECT DISTINCT implementation.id, implementation.name, implementation.fullName
  FROM openml.implementation, openml_exporting.input
  WHERE input.implementation_id = implementation.id;
