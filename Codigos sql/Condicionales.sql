
---- CONDICIONALES PIF
/**
IF(EXPRESION) THEN
     INSTRUCIIONES
ELSIF (EXPRESION) THEN
    INSTRUCCIONES 
ELSE
    INSTRUCCIONES 
END IF ;

--- ejemplo de uso 

DECLARE 
   X NUMBER :=:
   
   
   CON LA FECHA DEL SISTEMA DETERMINE SI LA FECHA DE HOY ES UN NUMERO PRIMO , SI ES PRIMO QUE LANCE UN MENSAJE QUE DIGA 'ES PRIMO'
   
   DECLARE
    vd_hoy INT;
BEGIN
    SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'DD')) INTO vd_hoy FROM DUAL;
    IF vd_hoy = 2 THEN
        DBMS_OUTPUT.PUT_LINE(' ES PRIMO');
    ELSIF vd_hoy <= 1 OR MOD(vd_hoy, 2) = 0 THEN
        DBMS_OUTPUT.PUT_LINE(' NO ES PRIMO');
    ELSE
        DBMS_OUTPUT.PUT_LINE('HOLA PRIMO ');
    END IF;
END;

**/ 


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




DECLARE
  x NUMBER := 0;
BEGIN
  LOOP
    DBMS_OUTPUT.PUT_LINE('Inside loop:  x = ' || TO_CHAR(x));
    x := x + 1;  
    EXIT WHEN x > 3;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('After loop:  x = ' || TO_CHAR(x));
END;
/
 
----------------------------------------------------------------------------------------------
---- LOOP fibonachi

DECLARE
    vn_a NUMBER := 0; 
    vn_b NUMBER := 1;
BEGIN
    WHILE vn_a <= 100 LOOP
        dbms_output.put_line(vn_a); 
        vn_b := vn_a + vn_b;  
        vn_a := vn_b - vn_a; 
    END LOOP;
END;
/

---------------------------------------------------------------------------------------
---- while
/**

se repite mientras se cumpla la condicion o expresion 

while(expresion) loop
-- intruccion 
end loop;


**/


--- ejercicio : minimo como un multiplo 


DECLARE
    n NUMBER := 25;  
    m NUMBER := 2;    -
    i NUMBER := 1;
BEGIN

    WHILE i <= 1 LOOP
        IF (n MOD m = 0) THEN
            DBMS_OUTPUT.PUT_LINE('ES MÚLTIPLO');
        ELSE
            DBMS_OUTPUT.PUT_LINE('NO ES MÚLTIPLO');
        END IF;

        i := i + 1;
    END LOOP;
END;
/
-----------------------------------------------------------------------------------------------

--- FOR 
/**
BEGIN
FOR X IN 1..50 LOOP
DBMS_OUT.PUT_lINE(2*X);
END LOOP;
END;


REVERSE = REVERSA 

GEGIN 
FOR X IN REVERSE 1.50 LOOP
DMS_OUTPUT.PUT_LINE(2*X);
END LOOP;
END;
**/


--- EJERCICIO 
---encontrar dos numeros que al cuadrado de n un numero x con for 

DECLARE
  vn_numero1 NUMBER := 64;
BEGIN
  FOR x IN 1 .. 10 LOOP
    IF x * x = vn_numero1 THEN
      DBMS_OUTPUT.PUT_LINE('TRUE: ' || x || '^2 = ' || vn_numero1);
    END IF;
  END LOOP;
END;
/












                                                                                                                                                                                
