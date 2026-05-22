-- Habilita la visualización de mensajes generados por DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Consulta todos los registros de la tabla EMPLOYEES
SELECT * 
FROM tduartec.employees;

-- Crea una nueva tabla llamada EMPLOYEES_2
-- copiando la estructura y los datos de HR.EMPLOYEES
CREATE TABLE EMPLOYEES_2 AS 
SELECT * 
FROM HR.EMPLOYEES;