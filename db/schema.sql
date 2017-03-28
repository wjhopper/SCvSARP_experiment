CREATE DATABASE FAM_SCvSARP;
\c fam_scvsarp

CREATE TABLE participants (
  subject smallserial NOT NULL,
  "group" character varying(9) NOT NULL,
  email character varying(40) UNIQUE NOT NULL,
  sessions_completed smallint NOT NULL,
  rng_seed bigint NOT NULL,
  computer character varying(20) NOT NULL,
  PRIMARY KEY(subject)
);

CREATE TABLE stimuli (
  id smallserial UNIQUE NOT NULL,
  target character varying(12) NOT NULL,
  semantic_cue character varying(12) UNIQUE NOT NULL,
  episodic_cue character varying(12) UNIQUE NOT NULL,
  PRIMARY KEY(target)
);

COPY stimuli(target, semantic_cue, episodic_cue)
FROM 'C:\Users\will\source\SCvSARP_experiment\db\stimuli_table.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE lists (
  subject smallint NOT NULL references participants(subject) ON DELETE CASCADE,
  id smallint NOT NULL references stimuli(id),
  target character varying(12) NOT NULL,
  semantic_cue character varying(12) NOT NULL,
  episodic_cue character varying(12) NOT NULL,
  session smallint NOT NULL,
  list smallint NOT NULL,
  practice character(1) NOT NULL,
  UNIQUE (target, semantic_cue, episodic_cue),
  PRIMARY KEY(subject, id)
);

CREATE INDEX ON lists(session);

CREATE TABLE study (
  subject smallint NOT NULL references participants(subject) ON DELETE CASCADE,
  session smallint NOT NULL,
  list smallint NOT NULL,
  id smallint NOT NULL references stimuli(id),
  cue character varying(12) NOT NULL,
  target character varying(12) NOT NULL,
  onset double precision NOT NULL,
  PRIMARY KEY(subject, id),
  UNIQUE (cue, target)
);

CREATE TABLE study_practice (
  subject smallint NOT NULL references participants(subject) ON DELETE CASCADE,
  session smallint NOT NULL,
  list smallint NOT NULL,
  id smallint NOT NULL references stimuli(id),
  cue character varying(12) NOT NULL,
  target character varying(12) NOT NULL,
  onset double precision NOT NULL,
  PRIMARY KEY(subject, id),
  UNIQUE (cue, target)
);


CREATE TABLE test_practice (
  subject smallint NOT NULL references participants(subject) ON DELETE CASCADE,
  session smallint NOT NULL,
  list smallint NOT NULL,
  id smallint NOT NULL references stimuli(id),
  cue character varying(12) NOT NULL,
  target character varying(12) NOT NULL,
  onset double precision NOT NULL,
  recalled smallint NOT NULL,
  latency double precision,
  FP double precision,
  LP double precision,
  advance double precision,
  response character varying(20),
  PRIMARY KEY(subject, id),
  UNIQUE (cue, target)
);

CREATE TABLE final_test (
  subject smallint NOT NULL references participants(subject) ON DELETE CASCADE,
  session smallint NOT NULL,
  list smallint NOT NULL,
  id smallint NOT NULL references stimuli(id),
  cue character varying(12) NOT NULL,
  target character varying(12) NOT NULL,
  onset double precision NOT NULL,
  recalled smallint NOT NULL,
  latency double precision,
  FP double precision,
  LP double precision,
  advance double precision,
  response character varying(20),
  PRIMARY KEY(subject, id),
  UNIQUE (cue, target)
);

CREATE ROLE will LOGIN;
GRANT ALL PRIVILEGES ON DATABASE "fam_sarp" TO will;
GRANT ALL PRIVILEGES ON SCHEMA public TO will;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO will;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO will;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO will;
