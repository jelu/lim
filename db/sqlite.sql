CREATE TABLE master
(
	master_id				INTEGER PRIMARY KEY,
	master_name				VARCHAR(255) NOT NULL,
	master_host				VARCHAR(255) NOT NULL,
	master_port				INTEGER NOT NULL,
	
	UNIQUE (master_name)
);

CREATE TABLE agent
(
	agent_id				INTEGER PRIMARY KEY,
	agent_name				VARCHAR(255) NOT NULL,
	agent_host				VARCHAR(255) NOT NULL,
	agent_port				INTEGER NOT NULL,
	
	UNIQUE (agent_name)
);

CREATE TABLE software_type
(
	software_type_id		INTEGER PRIMARY KEY,
	software_type_name		VARCHAR(255) NOT NULL,
	software_type_display	VARCHAR(255) NOT NULL,
	
	UNIQUE (software_type_name)
);

INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'bind', 'ISC Berkeley Internet Name Domain (BIND)' );
INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'nsd', 'Name Server Daemon (NSD)' );
INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'unbound', 'Unbound' );
INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'pdns', 'PowerDNS' );
INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'knot', 'Knot DNS' );

INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'opendnssec', 'OpenDNSSEC' );
INSERT INTO software_type ( software_type_name, software_type_display ) VALUES ( 'zkt', 'DNSSEC Zone Key Tool ' );

CREATE TABLE software_module
(
	software_module_id		INTEGER PRIMARY KEY,
	software_module_name	VARCHAR(255) NOT NULL,
	software_module_perllib	VARCHAR(255) NOT NULL,

	UNIQUE (software_module_name)
);

CREATE TABLE software
(
	software_id				INTEGER PRIMARY KEY,
	agent_id				INTEGER NOT NULL,
	software_type_id		INTEGER NOT NULL,
	software_module_id		INTEGER NOT NULL,
	software_version		VARCHAR(255) NOT NULL,
	
	UNIQUE (agent_id, software_type_id),
	
	FOREIGN KEY (agent_id) REFERENCES agent(agent_id),
	FOREIGN KEY (software_type_id) REFERENCES software_type(software_type_id),
	FOREIGN KEY (software_module_id) REFERENCES software_module(software_module_id)
);

