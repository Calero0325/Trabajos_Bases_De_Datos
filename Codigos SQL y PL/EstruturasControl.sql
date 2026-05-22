--- ESTRUCTURAS DE CONTROL
/*
En PL/SQL las estructuras de control permiten
tomar decisiones y repetir instrucciones.

Principales estructuras:
- IF
- LOOP
- WHILE
- FOR
- GOTO
*/

--- ESTRUCTURA IF


IF (expresion) THEN
    instrucciones
ELSIF (expresion) THEN
    instrucciones
ELSE
    instrucciones
END IF;


--- GOTO Y ETIQUETAS

/*
La instrucción GOTO permite saltar
a una etiqueta específica.

Sintaxis:

GOTO etiqueta;

<<etiqueta>>
*/

SET SERVEROUTPUT ON;

--- EJEMPLO 1
--- VALIDAR SI EL DÍA ACTUAL ES PRIMO

DECLARE
    vd_hoy INT;
BEGIN

    SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'DD'))
    INTO vd_hoy
    FROM DUAL;

    IF vd_hoy = 2 THEN

        DBMS_OUTPUT.PUT_LINE('ES PRIMO');

    ELSIF vd_hoy <= 1 OR MOD(vd_hoy, 2) = 0 THEN

        DBMS_OUTPUT.PUT_LINE('NO ES PRIMO');

    ELSE

        DBMS_OUTPUT.PUT_LINE('HOLA PRIMO');

    END IF;

END;
/

-- DESCRIPCIÓN
/*
Este ejemplo valida si el día actual
del mes es un número primo.

*/


DECLARE

    dia NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'DD'));

BEGIN

    IF dia IN (2,3,5,7,11,13,17,19,23,29,31) THEN
        GOTO primo;
    ELSE
        GOTO noprimo;
    END IF;

<<primo>>
    DBMS_OUTPUT.PUT_LINE('HOLA PRIMO');
    GOTO fin;

<<noprimo>>
    DBMS_OUTPUT.PUT_LINE('NO ES PRIMO');

<<fin>>
    NULL;

END;
/

--- DESCRIPCIÓN
/*
Este ejemplo utiliza GOTO y etiquetas.
*/


DECLARE

    vn_a NUMBER := 0;
    vn_b NUMBER := 1;
    vn_c NUMBER;

BEGIN

    LOOP

        EXIT WHEN vn_a > 100;

        DBMS_OUTPUT.PUT_LINE(vn_a);

        vn_c := vn_a + vn_b;
        vn_a := vn_b;
        vn_b := vn_c;

    END LOOP;

END;
/

--- DESCRIPCIÓN
/*
Este ejemplo imprime la serie Fibonacci
hasta llegar a 100 utilizando LOOP.

Cada número se calcula sumando
los dos anteriores.
*/
--- MÍNIMO COMÚN MÚLTIPLO

DECLARE

   a NUMBER := 12;
   b NUMBER := 18;

   mcd NUMBER;
   mcm NUMBER;

   x NUMBER;
   y NUMBER;

BEGIN

   x := a;
   y := b;

   WHILE y != 0 LOOP

      mcd := MOD(x, y);
      x := y;
      y := mcd;

   END LOOP;

   mcd := x;

   mcm := (a * b) / mcd;

   DBMS_OUTPUT.PUT_LINE('El MCM es: ' || mcm);

END;
/

-- DESCRIPCIÓN
/*
Este ejemplo calcula el mínimo común múltiplo.

Primero obtiene el máximo común divisor
usando WHILE y luego calcula el MCM.
*/


DECLARE

    vn_numerouno NUMBER := 64;
    vn_numeroraiz NUMBER := 0;

BEGIN

    FOR vn_numeroraiz IN 1..SQRT(vn_numerouno) LOOP

        IF ((vn_numeroraiz * vn_numeroraiz)= vn_numerouno) THEN

            DBMS_OUTPUT.PUT_LINE(vn_numeroraiz);

        END IF;

    END LOOP;

END;
/


--- BUCLES EN PL/SQL

/*
LOOP
Se ejecuta indefinidamente
hasta usar EXIT.

WHILE
Se ejecuta mientras
la condición sea verdadera.

FOR
Permite recorrer rangos
de valores automáticamente.
*/

--- EJEMPLO FOR

BEGIN

    FOR X IN 1..10 LOOP

        DBMS_OUTPUT.PUT_LINE(2 * X);

    END LOOP;

END;
/

--- EJEMPLO FOR REVERSE

BEGIN

    FOR X IN REVERSE 1..10 LOOP

        DBMS_OUTPUT.PUT_LINE(2 * X);

    END LOOP;

END;
/