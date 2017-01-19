CREATE DATABASE FAM_SARP;
\c fam_sarp

CREATE TABLE participants (
  subject smallserial NOT NULL,
  email character varying(40) UNIQUE NOT NULL,
  sessions_completed smallint,
  PRIMARY KEY(subject)
);


CREATE TABLE stimuli (
  id smallserial NOT NULL,
  target character varying(12) NOT NULL,
  semantic_cue_1 character varying(12) NOT NULL,
  semantic_cue_2 character varying(12) NOT NULL,
  semantic_cue_3 character varying(12) NOT NULL,
  episodic_cue character varying(12) NOT NULL,
  PRIMARY KEY(target)
);

COPY stimuli(target, semantic_cue_1, semantic_cue_2, semantic_cue_3, episodic_cue)
FROM 'C:\Users\will\source\FAM_SARP_experiment\db\stimuli_table.csv' DELIMITER ',' CSV HEADER;
