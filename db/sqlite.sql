CREATE TABLE agent
(
	agent_id		INTEGER PRIMARY KEY,
	agent_name		VARCHAR(255) NOT NULL,
	agent_host		VARCHAR(255) NOT NULL,
	agent_port		INTEGER NOT NULL
);
