SET serveroutput ON; 

DECLARE 
fecha TIMESTAMP;
BEGIN
    SELECT sysdate INTO fecha FROM dual;
    dbms_output.put_line('la fecha es :' || fecha);
END;

---- Decir hola mundo
BEGIN
dbms_output.put_line('si');
end;



----- declarar una variable 
DECLARE
vv_miPrimeraVariable VARCHAR2(50) := 'hola mundo' ;
BEGIN
dbms_output.put_line(vv_miPrimeraVariable);
end;




----- Ejercicio de epleado traer el nombre del empleado

DECLARE
vv_nombre VARCHAR2(50) ;
vv_apellido VARCHAR2(50);
BEGIN
SELECT first_name , last_name INTO vv_nombre,vv_apellido
FROM HR.EMPLOYEES
WHERE employee_id =110;
dbms_output.put_line('El nombre del empleado es :' || vv_nombre );
end;



----- Ejercicio de epleado TARER TODA LA INFORMACION

DECLARE
    vv_nombre hr.employees.first_name%TYPE;
    vv_nombre hr.employees.last_name%TYPE;
BEGIN
    SELECT
        first_name,
        last_name
    INTO vv_nombre , last_name
    FROM
        hr.employees
    WHERE
        employee_id = 110;

    dbms_output.put_line('El nombre del empleado es :' || first_name|| ' ' || last_name);
END;

---------

DECLARE
    vv_empleado HR.EMPLOYEES%ROWTYPE;
BEGIN
    SELECT *
    INTO vv_empleado
    FROM
        HR.EMPLOYEES
    WHERE
        employee_id IN (110,108)
    dbms_output.put_line('El nombre del empleado es :' || vv_empleado.first_name);
END;




---- DECLARE (BLOQUE ANONIMO )
---- select serveroutput  (esto es paraq que cada vez se haga ingreso a la base )
----(begin - end ) = logica de programacion del begin hasta el end , si no esta ninguna de los dos no funciona el programa

-----------------------------------------------------------------------------------------------------------------------------------------
---- REGLAS DEL CURSO TIPOS DE VARIABLES 

---- variables
---- vn_xxx (variable numerica  INT )
---- vd_xxx (DATE)
---- vv_xxx   (varchar)
---- vdo_xxx  (double) 

---- Contantes 
---- cn_xxx (variable numerica  INT )
---- cd_xxx (DATE)
---- cv_xxx   (varchar)
---- cdo_xxx  (double) 
---- control f7 es identar el codigo 


--- prefijos 
SP_nombre....

--- etiquetas 
<etiqueta>


--- nombre al final de la clase 

---------------------------------------------------------------------------------------------------------------------------------------------

---- vv_miPrimeraVariable := 'Hola mundo';  el := es la asignacion de informacion en la varibale
---- || ES PARA CONCATENAR 

---- %type





 