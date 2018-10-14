-- Copy only runs from our upload, and for multiple runs use only the latest run. Also remove runs without evaluations.
INSERT INTO openml_exporting.run
  SELECT r1.rid, r1.setup, r1.task_id
  FROM openml_native.run AS r1
  WHERE r1.start_time = (SELECT MAX(r2.start_time) FROM run AS r2 WHERE r2.setup = r1.setup AND r2.task_id = r1.task_id)
    AND r1.rid IN (SELECT source FROM openml_native.evaluation)
    AND uploader = 2702
    AND task_id = 3;
