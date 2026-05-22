SET SERVEROUTPUT ON;

--TEMA : CURSORES

/*
Un cursor es una estructura utilizada en PL/SQL
para recorrer los resultados obtenidos por una consulta.

Conceptos importantes:
- OPEN  -> Abre el cursor
- FETCH -> Obtiene los datos fila por fila
- CLOSE -> Cierra el cursor
- LOOP  -> Permite iterar sobre los registros

Tipos:
- Cursor explícito  -> Creado manualmente por el programador
- Cursor implícito  -> Oracle lo maneja automáticamente
*/

--EJEMPLO 
--Imprimir datos de la tabla pais utilizando un cursor explícito

DECLARE

    CURSOR cursor_paises IS
    SELECT
        id_pais,
        nombre_pats
    FROM pais;

    idr NUMBER(2);
    nom VARCHAR2(50);

BEGIN

    -- Abrir cursor
    OPEN cursor_paises;

    -- Obtener primer registro
    FETCH cursor_paises INTO
        idr,
        nom;

    -- Imprimir resultado
    DBMS_OUTPUT.PUT_LINE(idr || ' ' || nom);

    -- Cerrar cursor
    CLOSE cursor_paises;

END;
/

-- DESCRIPCIÓN
/*
Este ejemplo crea un cursor explícito llamado cursor_paises
que consulta los datos de la tabla pais.
*/


--EJEMPLO 2
--Cursor explícito con parámetro


DECLARE

    CURSOR prueba(vv_cheto NUMBER) IS
    SELECT
        first_name,
        employee_id
    FROM tduartec.employees
    WHERE department_id = vv_cheto;

    vv_nombre VARCHAR2(50);
    vv_id NUMBER(10);

    vv_cheto NUMBER(20) := 80;

BEGIN

    -- Abrir cursor enviando parámetro
    OPEN prueba(vv_cheto);

    LOOP

        -- Obtener registros
        FETCH prueba INTO
            vv_nombre,
            vv_id;

        -- Salir cuando no existan más registros
        EXIT WHEN prueba%NOTFOUND;

        -- Imprimir información
        DBMS_OUTPUT.PUT_LINE(vv_nombre || ' ' || vv_id);

    END LOOP;

    -- Cerrar cursor
    CLOSE prueba;

END;
/


-- DIFERENCIA ENTRE CURSOR EXPLÍCITO E IMPLÍCITO

/*
Cursor explícito:
- El programador controla el cursor manualmente
- Se usa para recorrer múltiples registros
- Requiere OPEN, FETCH y CLOSE

Cursor implícito:
- Oracle lo controla automáticamente
- Más simple y rápido para consultas pequeñas
- No requiere manejo manual
*/

SELECT *
FROM tduartec.employees;