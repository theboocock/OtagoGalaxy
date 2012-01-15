/* Ftp setup SQL script */
ALTER ROLE galaxyftp PASSWORD '1234';
GRANT SELECT ON galaxy_user TO galaxyftp;
