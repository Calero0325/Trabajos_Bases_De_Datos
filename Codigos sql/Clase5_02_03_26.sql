SET serveroutput ON; 


---- tema a estudiar (  CURSOR  )
---- OPEN (Curso explicito )
---- close (Cerrar el cursor )
---- iteracion 




---- 1 impirmir todos los empleados a travez de un cursor a travez del departamento 80 


DECLARE
    CURSOR cursor_paises IS
    SELECT
        id_pais,
        nombre_pats
    FROM
        pais;

    idr NUMBER(2);
    nom VARCHAR2(50);
BEGIN
    OPEN cursor_paises;
    FETCH cursor_paises INTO
        idr,
        nom;
    dbms_output.put_line(idr
                         || ' '
                         || nom);
    CLOSE cursor_paises;
END;
/


DECLARE
    CURSOR prueba (vv_cheto number ) IS
    SELECT
        first_name,
        employee_id
    FROM
        tduartec.employees
    WHERE
        department_id = vv_cheto;

    vv_nombre VARCHAR2(50);
    vv_id     NUMBER(10);
    vv_cheto number(20) :=80;
BEGIN
    OPEN prueba(vv_cheto);
    LOOP
        FETCH prueba INTO
            vv_nombre,
            vv_id;
        EXIT WHEN prueba%NOTFOUND;
        dbms_output.put_line(vv_nombre
                             || ' '
                             || vv_id);
    END LOOP;

    CLOSE prueba;
END;
/

---------------------------------------------------------------------------------------------


---- cursor implicito 

--- comparar un cursos explicito e implicto en tiempo  , buscar cual es mas eficiente 

---- cuantos hay que pagarles al empleados en el mes de marzo 


select * 
from tduartec.employess;
