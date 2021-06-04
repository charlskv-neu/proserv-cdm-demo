IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'proserv')
BEGIN
  CREATE DATABASE proserv;
END;
GO