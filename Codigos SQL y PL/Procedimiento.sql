SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE sp_mensaje (param_nombre IN VARCHAR2)
/*
Autor: Samuel Calero
Fecha: 23/02/2026
Descripcion: genera un texto saludando a alguien.
*/
IS
    vv_mensaje VARCHAR2(100);
BEGIN
    vv_mensaje := 'Hola ' || param_nombre || ' y Diomedes';
    dbms_output.put_line(vv_mensaje);
END sp_mensaje;
/

-------------------------------------------------------------------------------------
--Esto es para invocar el procedimiento almacenado

BEGIN
    sp_mensaje ('Samuel'); 
END;
/

--- EJERCICIO CON VALOR EN DEFAULT 

CREATE OR REPLACE PROCEDURE sp_mensajeConDefault (param_nombre IN VARCHAR2 DEFAULT 'Samuel')
/*
Autor: Samuel Calero
Fecha: 23/02/2026
Descripcion: Este sp genera un texto saludando a alguien usando valor en default.
*/
IS
    vv_mensaje VARCHAR2(100);
BEGIN
    vv_mensaje := 'Hola ' || param_nombre || ' y yo ';
    dbms_output.put_line(vv_mensaje);
END sp_mensajeConDefault;
/

BEGIN
    sp_mensajeConDefault (); 
END;
/