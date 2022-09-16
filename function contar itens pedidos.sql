SELECT  NUNOTA, 
        CODPARC, 
        NOMEPARC, 
        DTNEG,
        COUNT (DISTINCT (CODPROD))     CONTADORITENS,
        GRUP 
        FROM (
    SELECT       CAB.NUNOTA,
             CAB.CODPARC,
             PAR.NOMEPARC,
             CAB.DTNEG,
             ITE.CODPROD,
             (SELECT GRUP FROM  (SELECT CODPROD, (CASE 
                WHEN (PRO2.AD_CODFAMILIA=9)                     THEN 'Agua'
                WHEN (PRO2.AD_CODFAMILIA in (1,2,3,4,5,6,7,8))  THEN 'Refri'
                WHEN (PRO2.AD_CODFAMILIA=10)                    THEN 'Cerveja'
                WHEN (PRO2.AD_CODFAMILIA=11)                    THEN 'Sucos'
                ELSE 'sem_grupo' END) as GRUP  FROM TGFPRO PRO2 WHERE PRO2.CODPROD=PRO.CODPROD)  )AS GRUP          
             
        FROM TGFCAB CAB,
             TGFITE ITE,
             TGFPRO PRO,
             TGFPAR PAR
       WHERE     CAB.TIPMOV = 'V'
             AND ITE.CODPROD = PRO.CODPROD
             AND CAB.CODPARC = PAR.CODPARC
             AND CAB.NUNOTA = ITE.NUNOTA
             AND CAB.DTNEG='08/04/2022'  )
 GROUP BY NUNOTA, CODPARC, NOMEPARC, DTNEG, GRUP
      HAVING COUNT (DISTINCT (CODPROD)) > 1
      ORDER BY NUNOTA DESC