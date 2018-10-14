-- Create temporary database
DROP DATABASE IF EXISTS openml_exporting;
CREATE DATABASE openml_exporting;

-- Copy table structures
CREATE TABLE openml_exporting.run LIKE openml_native.run;
CREATE TABLE openml_exporting.input LIKE openml_native.input;
CREATE TABLE openml_exporting.input_setting LIKE openml_native.input_setting;
CREATE TABLE openml_exporting.evaluation LIKE openml_native.evaluation;
CREATE TABLE openml_exporting.implementation LIKE openml_native.implementation;

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
