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
