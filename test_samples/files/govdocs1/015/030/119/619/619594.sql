-- ================================================================================
-- ================================================================================
-- E. Gallas
-- June 6, 2006
--
-- write update statments to load the new columns with the new luminosity
-- based on existing values and the given functions.
--
-- This file: 060606_UpdateLum.sql
-- ================================================================================
-- ================================================================================
-- I started thinking about individual update statements in the files here,
-- but then the update progress cannot be monitored and Greg ... might change the
-- constant values and I don't have the exact LBN ranges yet, 
-- so I am trying the plsql below instead of these files
-- so that constants and LBN period ranges go in one place only.
-- ================================================================================

/*  Define a table that stores the lbn ranges (LO and HI) for each region and their
    multiplicative constants here: 1=linear, 2=square, 3=cube.
    ALL THE VARIABLES THAT MIGHT CHANGE ARE IN THIS TABLE 
    (the LBN ranges and their constants) */

-- PROMPT Creating Table 'LumConstTable' containing the 
--        LBN boundaries (inclusive) of each data taking period and their
--        linear, square, and cubic multiplicative constants in each period.

DROP TABLE LumConstTable;
CREATE TABLE LumConstTable (PERIOD VARCHAR2(10),
                            LBN_LO INTEGER,
                            LBN_HI INTEGER,
                            CONST1 NUMBER,
                            CONST2 NUMBER,
                            CONST3 NUMBER);
DELETE FROM LumConstTable;

/* ================================================================================
*/
-- the following values were in email from Greg Snow 13-Jun-06 8:55
insert into LumConstTable values 
	('Run 2A:A', 1129853, 3736259, 1.026,     0.,          0.);
insert into LumConstTable values 
	('Run 2A:B', 3736260, 3757957, 0.975357,  0.00231534, -2.30643e-5);
insert into LumConstTable values 
	('Run 2A:C', 3757958, 3921401, 1.039764, -0.00174996,  3.12866e-5);
insert into LumConstTable values 
	('Run 2A:D', 3921405, 4317937, 1.01718,  -9.34606e-4,  7.4107e-6);
insert into LumConstTable values 
	('Run 2A:E', 4317939, 4715213, 1.125,     0.,          0.);
insert into LumConstTable values 
	('Run 2B',   4715214, 9999999, 1.000,     0.,          0.);

-- ================================================================================

COMMIT;

-- ================================================================================
set serveroutput on;

declare

/* create a DEBUG flag for turning on/off print statements */
DEBUG VARCHAR2(3) := 'on';

/* counter_number == number of updates since the last commit;
/* commit every commit_count */
counter INTEGER :=0;
commit_count INTEGER := 99999;
count_period_changes INTEGER :=0;

/*  these are to double check the counts at the end for DL, EL, LT tables */
total_DL_count INTEGER :=0;
total_EL_count INTEGER :=0;
total_LT_count INTEGER :=0;

/* declare variables for the 3 constants (same names as the columns)  */
PERIOD LumConstTable.PERIOD%type;
LBN_LO LumConstTable.LBN_LO%type;
LBN_HI LumConstTable.LBN_HI%type;
CONST1 LumConstTable.CONST1%type;
CONST2 LumConstTable.CONST2%type;
CONST3 LumConstTable.CONST3%type;

/* declare variables for the new NIM and new VME luminosity values */
thisLBN LumConstTable.LBN_LO%type;
thisLum DELIVERED_LUMS.DEL_LUM_NIM%type;

/* declare a function for the new luminosity */
--NewLuminosity DELIVERED_LUMS.DEL_LUM_NIM%type := CONST1*thisLum + 
--                                                 CONST2*thisLum**2 + 
--                                                CONST3*thisLum**3;


/* I need a place to store the new luminosity columns */
newNIM DELIVERED_LUMS.DEL_LUM_NIM%type;
newVME DELIVERED_LUMS.DEL_LUM_NIM%type;

new_L1NIM DELIVERED_LUMS.DEL_LUM_NIM%type;
new_L1VME DELIVERED_LUMS.DEL_LUM_NIM%type;
new_RECNIM DELIVERED_LUMS.DEL_LUM_NIM%type;
new_RECVME DELIVERED_LUMS.DEL_LUM_NIM%type;

/* declare a string to store the SQL */
mySQL VARCHAR2(1000) := '';

/* keep track of the previous LBN so I can reduce queries for constants */
lastLBN LumConstTable.LBN_LO%type    := 0;
lastPeriod LumConstTable.PERIOD%type := 'blah';

-- ================================================================================
/* DELIVERED_LUMS Table  ------------------------------------------------------- */
cursor DL_data is
  select LBN,
         TICK_NUM,
         DEL_LUM_NIM,
 	 DEL_LUM_VME 
         from DELIVERED_LUMS
	where DEL_LUM_NIM_NEW is null;
--  order by LBN,TICK_NUM;
/* EXPOSED_LUMS Table  ------------------------------------------------------- */
cursor EL_data is
  select LBN,
	 EG_NUM,
         TICK_NUM,
         EXP_LUM_NIM,
 	 EXP_LUM_VME 
         from EXPOSED_LUMS
	where exp_lum_nim_new is null;
--  order by LBN,EG_NUM,TICK_NUM;
/* LBN_TRIGGERS Table  ------------------------------------------------------- */
cursor LT_data is
  select LBN,
 	 LT_ID,
         EG_NUM,
         L3_BIT_NAME,
	 L1_LUM_NIM,
 	 L1_LUM_VME,
	 REC_LUM_NIM,
 	 REC_LUM_VME 
         from LBN_TRIGGERS
	where L1_LUM_NIM_NEW is null;
--  order by LBN,LT_ID;

-- ================================================================================
begin
  /* Enable DBMS_OUTPUT and set the buffer size. 
	The buffer size can be between 1 and 1,000,000 */
  dbms_output.enable(1000000);
  dbms_output.put_line ('Working on Delivered_Lums Table');

  mySQL := 'SELECT LOCALTIMESTAMP FROM DUAL';
  EXECUTE IMMEDIATE mySQL;

-- ================================================================================
/* DELIVERED_LUMS Table  ------------------------------------------------------- */
  for thisRow in DL_data loop
    begin

      thisLBN := thisRow.LBN;
      /* get constants for this LBN (print if PERIOD != last Period) */
      IF lastLBN!=thisLBN then
        BEGIN

          mySQL := 'SELECT PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 
            from LumConstTable 
            where LBN_LO<='||to_char(thisLBN)||' and LBN_HI>='||to_char(thisLBN);

          EXECUTE IMMEDIATE mySQL into PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 ;

	  EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
	    dbms_output.put_line ('DL: -----------------------------------------');
  	    dbms_output.put_line ('Error: LBN not found in known LBN periods !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('DL: -----------------------------------------');
	    exit;
	  WHEN TOO_MANY_ROWS THEN
	    dbms_output.put_line ('DL: -----------------------------------------');
            dbms_output.put_line ('Error: LBN found in more than one PERIOD  !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('DL: -----------------------------------------');
	    exit;
	  WHEN OTHERS THEN
	    dbms_output.put_line ('DL: -----------------------------------------');
            dbms_output.put_line ('Other Error');
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('DL: -----------------------------------------');
	    exit;
	END;

	IF DEBUG = 'on' AND PERIOD != lastPeriod then
	  count_period_changes  := count_period_changes + 1;
	  IF count_period_changes<10 THEN
            dbms_output.put_line ('DL: -----------------------------------------');
	    dbms_output.put_line ('DL: New Period !!! '||PERIOD||
                       '  ('||LBN_LO||'-'||LBN_HI||') for LBN '||to_char(thisLBN));
          END IF;
        END IF;

      END IF;
      lastPeriod := PERIOD;
      lastLBN := thisLBN;

-- ================================================================================
-- Simply multiply all Run 2A luminosities by 1.155
      IF PERIOD!='Run 2B' THEN
        CONST1 := 1.155;
        CONST2 := 0.;
        CONST3 := 0.;
      ELSE
	CONST1 := 1.000;
      END IF;
-- ================================================================================

      /* Calculate new DEL_LUM_NIM luminosity ---------------------------------- */
      thisLum := thisRow.DEL_LUM_NIM;
      IF thisLum > 0. then
--old	newNIM := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        newNIM := CONST1 * thisLum;
      ELSE
        newNIM := thisLum;
      END IF;

/* ##?? look for new lum greater than old lum, stop if found */
      IF newNIM<thisLum THEN
	dbms_output.put_line ('error - new DL < old DL !!!');
	dbms_output.put_line ('Period = '||period||' on LBN '||to_char(thisLBN));
	dbms_output.put_line ('thisLum = '||to_char(thisLum));
	dbms_output.put_line ('CONST1 = '||to_char(CONST1));
	dbms_output.put_line ('CONST2 = '||to_char(CONST2));
	dbms_output.put_line ('CONST3 = '||to_char(CONST3));
	dbms_output.put_line ('CONST1*thisLum    = '||to_char(CONST1*thisLum));
	dbms_output.put_line ('CONST2*thisLum**2 = '||to_char(CONST2*thisLum**2));
	dbms_output.put_line ('CONST3*thisLum**3 = '||to_char(CONST3*thisLum**3));
	dbms_output.put_line ('newNIM = '||to_char(newNIM));
	RAISE CASE_NOT_FOUND;
      END IF;

      /* Calculate new DEL_LUM_VME luminosity ---------------------------------- */
      thisLum := thisRow.DEL_LUM_VME;
      IF thisLum > 0. then
--old	newVME := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        newVME := CONST1 * thisLum;
      ELSE
        newVME := thisLum;
      END IF;

      /* Update the table adding the new values -------------------------------- */
      UPDATE DELIVERED_LUMS 
  	     set DEL_LUM_NIM_NEW=newNIM,
                 DEL_LUM_VME_NEW=newVME 
             where LBN=thisLBN and
                 TICK_NUM=thisRow.TICK_NUM;

--      mySQL := 'UPDATE DELIVERED_LUMS 
--        SET DEL_LUM_NIM_NEW='||(newNIM)||
--          ',DEL_LUM_VME_NEW='||(newVME)||
--        ' WHERE LBN='||to_char(thisLBN)||
--        ' AND TICK_NUM='||to_char(thisRow.TICK_NUM);
--      dbms_output.put_line (to_char(mySQL));
--      EXECUTE IMMEDIATE mySQL;

      counter        := counter + 1;
      total_DL_count := total_DL_count + 1;

      /*  if counter > commit_count then commit */
      if counter>commit_count then
        dbms_output.put_line ('Commit; DL count is now '||to_char(total_DL_count));
        commit;
        counter:=0;
      end if;

      EXCEPTION 
        WHEN OTHERS THEN
	  dbms_output.put_line ('Update DL: ------------------------------------');
          dbms_output.put_line ('ERROR '||sqlerrm);
  	  RAISE_APPLICATION_ERROR(-20000,'DL: RAISE_APPLICATION_ERROR');

    end; 	/* end of begin enclosing loop over DL data */
  end loop; 	/* end of loop over DL data */

  /*  final commit for DL */
  dbms_output.put_line ('Final DL Commit.');
  commit;

  /*  print total DL */
  dbms_output.put_line ('DL: ---------------------------------------------------');
  dbms_output.put_line ('Total DL updates = '||to_char(total_DL_count));
  dbms_output.put_line ('DL Period changes = '||to_char(count_period_changes));
-- ================================================================================
  counter :=0;
  count_period_changes :=0;
  dbms_output.put_line ('Working on EXPOSED_Lums Table');
-- ================================================================================
/* EXPOSED_LUMS Table  ------------------------------------------------------- */
  for thisRow in EL_data loop
    begin

      thisLBN := thisRow.LBN;
      /* get constants for this LBN (print if PERIOD != last Period) */
      IF lastLBN!=thisLBN then
        BEGIN

          mySQL := 'SELECT PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 
            from LumConstTable 
            where LBN_LO<='||to_char(thisLBN)||' and LBN_HI>='||to_char(thisLBN);

	  IF DEBUG = 'on' AND PERIOD != lastPeriod then
	    dbms_output.put_line ('EL: -----------------------------------------');
	    dbms_output.put_line ('EL: New Period !!! '||PERIOD||
                       '  ('||LBN_LO||'-'||LBN_HI||') for LBN '||to_char(thisLBN));
	    dbms_output.put_line (mySQL);
	    dbms_output.put_line ('EL: -----------------------------------------');
          END IF;

          EXECUTE IMMEDIATE mySQL into PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 ;

	  EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
	    dbms_output.put_line ('EL: -----------------------------------------');
  	    dbms_output.put_line ('Error: LBN not found in known LBN periods !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('EL: -----------------------------------------');
	    exit;
	  WHEN TOO_MANY_ROWS THEN
	    dbms_output.put_line ('EL: -----------------------------------------');
            dbms_output.put_line ('Error: LBN found in more than one PERIOD  !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('EL: -----------------------------------------');
	    exit;
	  WHEN OTHERS THEN
	    dbms_output.put_line ('EL: -----------------------------------------');
            dbms_output.put_line ('Other Error');
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('EL: -----------------------------------------');
	    exit;
	END;

	IF DEBUG = 'on' AND PERIOD != lastPeriod then
	  dbms_output.put_line ('EL: -----------------------------------------');
	  dbms_output.put_line ('EL: New Period !!! '||PERIOD||
                     '  ('||LBN_LO||'-'||LBN_HI||') for LBN '||to_char(thisLBN));
	  dbms_output.put_line (mySQL);
	  dbms_output.put_line ('EL: -----------------------------------------');
        END IF;

      END IF;
      lastPeriod := PERIOD;
      lastLBN := thisLBN;

-- ================================================================================
-- Simply multiply all Run 2A luminosities by 1.155
      IF PERIOD!='Run 2B' THEN
        CONST1 := 1.155;
        CONST2 := 0.;
        CONST3 := 0.;
      ELSE
	CONST1 := 1.000;
      END IF;
-- ================================================================================

      /* Calculate new EXP_LUM_NIM luminosity ---------------------------------- */
      thisLum := thisRow.EXP_LUM_NIM;
      IF thisLum > 0. then
--old	newNIM := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        newNIM := CONST1 * thisLum;
      ELSE
        newNIM := thisLum;
      END IF;
















      /* Calculate new EXP_LUM_VME luminosity ---------------------------------- */
      thisLum := thisRow.EXP_LUM_VME;
      IF thisLum > 0. then
--old	newVME := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        newVME := CONST1 * thisLum;
      ELSE
        newVME := thisLum;
      END IF;

      /* Update the table adding the new values -------------------------------- */
      UPDATE EXPOSED_LUMS 
  	     set EXP_LUM_NIM_NEW=newNIM,
                 EXP_LUM_VME_NEW=newVME 
             where LBN=thisLBN and
	 	 EG_NUM=thisRow.EG_NUM and 
                 TICK_NUM=thisRow.TICK_NUM;








      counter        := counter + 1;
      total_EL_count := total_EL_count + 1;

      /*  if counter > commit_count then commit */
      if counter>commit_count then
        dbms_output.put_line ('Commit; EL count is now '||to_char(total_EL_count));
        commit;
        counter:=0;
      end if;

      EXCEPTION 
        WHEN OTHERS THEN
	  dbms_output.put_line ('Update EL: ------------------------------------');
          dbms_output.put_line ('ERROR '||sqlerrm);
  	  RAISE_APPLICATION_ERROR(-20000,'EL: RAISE_APPLICATION_ERROR');


    end; 	/* end of begin enclosing loop over EL data */
  end loop; 	/* end of loop over EL data */

  /*  final commit for EL */
  dbms_output.put_line ('Final EL Commit.');
  commit;

  /*  print total EL */
  dbms_output.put_line ('EL: ---------------------------------------------------');
  dbms_output.put_line ('Total EL updates = '||to_char(total_EL_count));
  dbms_output.put_line ('EL Period changes = '||to_char(count_period_changes));

-- ================================================================================
counter :=0;
dbms_output.put_line ('Working on LBN_TRIGGERS Table');
-- ================================================================================
/* LBN_TRIGGERS Table  ------------------------------------------------------- */
  for thisRow in LT_data loop
    begin

      thisLBN := thisRow.LBN;
      /* get constants for this LBN (print if PERIOD != last Period) */
      IF lastLBN!=thisLBN then
        BEGIN

          mySQL := 'SELECT PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 
            from LumConstTable 
            where LBN_LO<='||to_char(thisLBN)||' and LBN_HI>='||to_char(thisLBN);

          EXECUTE IMMEDIATE mySQL into PERIOD,LBN_LO,LBN_HI,CONST1,CONST2,CONST3 ;

	  EXCEPTION 
          WHEN NO_DATA_FOUND THEN 
	    dbms_output.put_line ('LT: -----------------------------------------');
  	    dbms_output.put_line ('Error: LBN not found in known LBN periods !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('LT: -----------------------------------------');
	    exit;
	  WHEN TOO_MANY_ROWS THEN
	    dbms_output.put_line ('LT: -----------------------------------------');
            dbms_output.put_line ('Error: LBN found in more than one PERIOD  !  '||
                                   to_char(thisLBN));
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('LT: -----------------------------------------');
	    exit;
	  WHEN OTHERS THEN
	    dbms_output.put_line ('LT: -----------------------------------------');
            dbms_output.put_line ('Other Error');
            dbms_output.put_line ('SQL CODE : '||mySQL);
            dbms_output.put_line ('ERROR '||sqlerrm);
	    dbms_output.put_line ('LT: -----------------------------------------');
	    exit;
	END;

	IF DEBUG = 'on' AND PERIOD != lastPeriod then
	  count_period_changes  := count_period_changes + 1;
	  IF count_period_changes<10 THEN
            dbms_output.put_line ('LT: -----------------------------------------');
	    dbms_output.put_line ('LT: New Period !!! '||PERIOD||
                       '  ('||LBN_LO||'-'||LBN_HI||') for LBN '||to_char(thisLBN));
          END IF;
        END IF;

      END IF;
      lastPeriod := PERIOD;
      lastLBN := thisLBN;

-- ================================================================================
-- Simply multiply all Run 2A luminosities by 1.155
      IF PERIOD!='Run 2B' THEN
        CONST1 := 1.155;
        CONST2 := 0.;
        CONST3 := 0.;
      ELSE
	CONST1 := 1.000;
      END IF;
-- ================================================================================

      /* Calculate new L1_LUM_NIM luminosity ----------------------------------- */
      thisLUM   := thisRow.L1_LUM_NIM;
      if thisLUM > 0. then
--old	new_L1NIM := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        new_L1NIM := CONST1 * thisLum;
      ELSE
        new_L1NIM := thisLum;
      END IF;

      /* Calculate new L1_LUM_VME luminosity ----------------------------------- */
      thisLUM := thisRow.L1_LUM_VME;
      if thisLUM > 0. then
--old	new_L1VME := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        new_L1VME := CONST1 * thisLum;
      ELSE
        new_L1VME := thisLum;
      END IF;

      /* Calculate new REC_LUM_NIM luminosity ----------------------------------- */
      thisLUM := thisRow.REC_LUM_NIM;
      if thisLUM > 0. then
--old	new_RECNIM := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        new_RECNIM := CONST1 * thisLum;
      ELSE
        new_RECNIM := thisLum;
      END IF;

      /* Calculate new REC_LUM_VME luminosity ----------------------------------- */
      thisLUM := thisRow.REC_LUM_VME;
      if thisLUM > 0. then
--old	new_RECVME := CONST1*thisLum + CONST2*thisLum**2 + CONST3*thisLum**3;
        new_RECVME := CONST1 * thisLum;
      ELSE
        new_RECVME := thisLum;
      END IF;

      /* Update the table adding the new values -------------------------------- */
      UPDATE LBN_TRIGGERS 
  	     set L1_LUM_NIM_NEW=new_L1NIM,
                 L1_LUM_VME_NEW=new_L1VME, 
                 REC_LUM_NIM_NEW=new_RECNIM,
                 REC_LUM_VME_NEW=new_RECVME 
             where LT_ID=thisRow.LT_ID;








      counter        := counter + 1;
      total_LT_count := total_LT_count + 1;

      /*  if counter > commit_count then commit */
      if counter>commit_count then
        dbms_output.put_line ('Commit; LT count is now '||to_char(total_LT_count));
        commit;
        counter:=0;
      end if;

      EXCEPTION 
        WHEN OTHERS THEN
	  dbms_output.put_line ('Update LT: ------------------------------------');
          dbms_output.put_line ('ERROR '||sqlerrm);
  	  RAISE_APPLICATION_ERROR(-20000,'LT: RAISE_APPLICATION_ERROR');

    end; 	/* end of begin enclosing loop over LT data */
  end loop; 	/* end of loop over LT data */

  /*  final commit for LT */
  dbms_output.put_line ('Final LT Commit.');
  commit;

  /*  print total LT */
  dbms_output.put_line ('LT: ---------------------------------------------------');
  dbms_output.put_line ('Total LT updates = '||to_char(total_LT_count));
  dbms_output.put_line ('LT Period changes = '||to_char(count_period_changes));
-- ================================================================================

  mySQL := 'SELECT LOCALTIMESTAMP FROM DUAL';
  EXECUTE IMMEDIATE mySQL;

EXCEPTION 
  WHEN OTHERS THEN
    dbms_output.put_line ('End of program: -------------------------------------');


/*  end of first begin loop over all tables; */
END;
/


















