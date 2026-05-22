SET SERVEROUTPUT ON;


-- OBTENER LA FECHA ACTUAL

DECLARE
    fecha TIMESTAMP;
BEGIN

    SELECT SYSDATE
    INTO fecha
    FROM dual;

    DBMS_OUTPUT.PUT_LINE('La fecha es: ' || fecha);

END;
/


BEGIN

    DBMS_OUTPUT.PUT_LINE('si');

END;
/


-- DESCRIPCIÓN
/*
Este es el ejemplo básico en PL/SQL.

Utiliza DBMS_OUTPUT.PUT_LINE para imprimir
un mensaje en consola.
*/


DECLARE

    vv_miprimeravariable VARCHAR2(50) := 'hola mundo';

BEGIN

    DBMS_OUTPUT.PUT_LINE(vv_miprimeravariable);

END;
/


-- DESCRIPCIÓN
/*
Este ejemplo muestra cómo declarar
una variable tipo VARCHAR2.

Luego se imprime el contenido de la variable.
*/

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
    FROM hr.employees
    WHERE employee_id = 110;

    DBMS_OUTPUT.PUT_LINE(
        'El nombre del empleado es: '
        || vv_nombre || ' ' || vv_apellido
    );

END;
/

-- DESCRIPCIÓN
/*
Este ejemplo utiliza SELECT INTO
para guardar datos de una consulta
en variables PL/SQL.

*/

---- TRAER INFORMACIÓN UTILIZANDO %TYPE

DECLARE

    vv_nombre   hr.employees.first_name%TYPE;
    vv_apellido hr.employees.last_name%TYPE;

BEGIN

    SELECT
        first_name,
        last_name
    INTO
        vv_nombre,
        vv_apellido
    FROM hr.employees
    WHERE employee_id = 110;

    DBMS_OUTPUT.PUT_LINE(
        'El nombre del empleado es: '
        || vv_nombre || ' ' || vv_apellido
    );

END;
/


-- DESCRIPCIÓN
/*
El atributo %TYPE permite que la variable
tome automáticamente el mismo tipo de dato
de una columna de la tabla.
*/


DECLARE

    vv_empleado HR.EMPLOYEES%ROWTYPE;

BEGIN

    SELECT *
    INTO vv_empleado
    FROM HR.EMPLOYEES
    WHERE employee_id = 110;

    DBMS_OUTPUT.PUT_LINE(
        'El nombre del empleado es: '
        || vv_empleado.first_name
    );

END;
/
