SET serveroutput ON;

DECLARE
    fecha TIMESTAMP;
BEGIN
    SELECT
        sysdate
    INTO fecha
    FROM
        dual;

    dbms_output.put_line('la fecha es :' || fecha);
END;

---- Decir hola mundo
BEGIN
    dbms_output.put_line('si');
END;






----- declarar una variable 
DECLARE
    vv_miprimeravariable VARCHAR2(50) := 'hola mundo';
BEGIN
    dbms_output.put_line(vv_miprimeravariable);
END;




----- Ejercicio de epleado traer el nombre del empleado

DECLARE
    vv_nombre   VARCHAR2(50);
    vv_apellido VARCHAR2(50);
BEGIN
    SELECT
        first_name,
        last_name
    INTO
        vv_nombre,
        vv_apellido
    FROM
        hr.employees
    WHERE
        employee_id = 110;

    dbms_output.put_line('El nombre del empleado es :' || vv_nombre);
END;



----- Ejercicio de epleado TARER TODA LA INFORMACION

DECLARE
    vv_nombre hr.employees.first_name%TYPE;
    vv_nombre hr.employees.last_name%TYPE;
BEGIN
    SELECT
        first_name,
        last_name
    INTO
        vv_nombre,
        last_name
    FROM
        hr.employees
    WHERE
        employee_id = 110;

    dbms_output.put_line('El nombre del empleado es :'
                         || first_name
                         || ' '
                         || last_name);
END;

---------

DECLARE VV_EMPLEADO HR . EMPLOYEES % ROWTYPE ; BEGIN SELECT * INTO VV_EMPLEADO
    FROM
        HR.EMPLOYEES
    WHERE
        employee_id IN (110,108)
    dbms_output.put_line('El nombre del empleado es :' || vv_empleado.first_name);
END;

------------------------------------------------------------------------
--- PREFIJO PARA LAS VARIABLES
--- vn_xxxxx ---> Forma correcta de crear una variable numerica.
--- vd_xxxx ---> Forma correcta de crear una variable de tipo Date.
--- vv_xxxx ---> Forma correcta de crear una variable de tipo Varchar.
--- vdo_xxx ----> Forma correcta de crear una variable de tipo double.
-------------------------------------------------------------------------
--- PREFIJO PARA LAS CONSTANTES
--- cn_xxx ---> Forma correcta de crear una variable numerica.
--- cd_xxx ---> Forma correcta de crear una variable de tipo Date.
--- cv_xxx ---> Forma correcta de crear una variable de tipo Varchar
--- cdo_xxx ----> Forma correcta de crear una variable de tipo double.
---------------------------------------------------------------------------
--- prefijo para los procedimientos almacenados.
--- sp_xxx
---------------------------------------------------------------------------
--- prefijo para los parametros
--- param_xxx
-----------------------------------------------------------------------------
--prefijo para funciones
---fn_xxx
-----------------------------------------------------------------------------------
-- prefijo para paquetes
--- pck_xxx
--------------------------------------------------------------------------------
-- prefijo pra triggers
-- TGR_xxx
------------------------------------------------------------------------------------


 