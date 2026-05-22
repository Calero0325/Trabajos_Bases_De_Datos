SET SERVEROUTPUT ON;

----------------------------------------------------------------------------------------------------------------
--- TRIGGERS (DISPARADORES)

/*
Un trigger es un bloque PL/SQL asociado a una tabla,
que se ejecuta automáticamente como consecuencia
de una instrucción SQL.

Prefijos para triggers:
TGR_I = INSERT
TGR_U = UPDATE
TGR_D = DELETE

Tipos:
- BEFORE  -> Se ejecuta antes de la acción
- AFTER   -> Se ejecuta después de la acción

Variables especiales:
:OLD -> Valor anterior
:NEW -> Valor nuevo
*/


--- EJEMPLO 

-- Trigger que se ejecuta antes de insertar un empleado

CREATE OR REPLACE TRIGGER TGR_I_EMPLOYEES
BEFORE INSERT
ON EMPLOYEES_2
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('Se insertó un nuevo empleado');
END;
/


--- PRUEBA 

INSERT INTO EMPLOYEES_2 (EMPLOYEE_ID,FIRST_NAME,,HIRE_DATE,JOB_ID) VALUES (
1,'Samuel',SYSDATE,'IT_PROG'
);