-- Copy only parameter values for the runs in run
INSERT IGNORE INTO openml_exporting.input_setting
  SELECT input_setting.setup, input_id, value
  FROM openml_native.input_setting, openml_exporting.run
  WHERE input_setting.setup = run.setup;

-- Copy only parameter definitions for the values in input_setting
INSERT IGNORE INTO openml_exporting.input
  SELECT id, fullName, implementation_id, name
  FROM openml_native.input
  JOIN openml_exporting.input_setting
  ON input.id = input_setting.input_id;

-- Copy only run results for the runs in run
INSERT INTO openml_exporting.evaluation
  SELECT source, function_id, value, stdev
  FROM openml_native.evaluation, openml_exporting.run
  WHERE evaluation.source = run.rid
  AND function_id IN (4,45,54,59,63);
  
-- Copy only implementation details for the implementations referenced in input
INSERT INTO openml_exporting.implementation
  SELECT DISTINCT implementation.id, implementation.fullName, implementation.name
  FROM openml_native.implementation, openml_exporting.input
  WHERE input.implementation_id = implementation.id;
