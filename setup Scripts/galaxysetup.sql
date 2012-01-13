/* Setup galaxy user database */
ALTER USER postgres WITH PASSWORD 'password';
ALTER USER galaxy WITH PASSWORD '1234';
GRANT ALL PRIVILEGES ON DATABASE galaxydb to galaxy;


