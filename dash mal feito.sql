WITH CONTABIL_AUX AS (
				SELECT 
					CODCTACTB,
					DESCRCTA,
					SUM(VLRLANC) AS VALOR,
					CODPARC,
					RAZAOSOCIAL
				FROM
					A001_CONCILIACLIFOR
				WHERE
					CONCILIADO='N'
					AND CODCTACTB in(58,572,569)
					AND REFERENCIA <= :DATAREF
					AND REFERENCIA >= '31/12/2017'
					AND (CODPARC IN (:CODPARC) OR :CODPARC IS NULL)
				GROUP BY
					CODCTACTB,
					DESCRCTA,
					CODPARC,
					RAZAOSOCIAL


				UNION ALL

				SELECT 
					LAN.CODCTACTB, 
					PLA.DESCRCTA, 
					SUM(CASE
                			WHEN TIPLANC = 'R' THEN (VLRLANC * (-1))
                			ELSE VLRLANC
            			END) AS VALOR,
					LAN.AD_CODPARC, 
					PAR.RAZAOSOCIAL
				FROM
					TCBLAN LAN, 
					TCBPLA PLA, 
					TGFPAR PAR
				WHERE LAN.CODCTACTB = PLA.CODCTACTB
				  AND LAN.AD_CODPARC = PAR.CODPARC
				  AND LAN.NUMLOTE = 9988
				  AND LAN.CODCTACTB IN(58,569,572)
				  AND (CODPARC IN (:CODPARC) OR :CODPARC IS NULL)
				  AND LAN.REFERENCIA <= :DATAREF
				GROUP BY
					LAN.CODCTACTB, 
					PLA.DESCRCTA, 
					LAN.AD_CODPARC, 
					PAR.RAZAOSOCIAL				  

),

FINANCEIRO_AUX AS (
                /* SUA CONSULTA COMO ANTES */
                SELECT
                    FIN.CODPARC AS CODPARC,
                    PAR.RAZAOSOCIAL AS RAZAOSOCIAL,
                    FIN.CODNAT AS CODNAT,
                    SUM(FIN.VLRDESDOB) AS SOMA_VLRDESDOB,
                    NAT.DESCRNAT AS DESCRNAT
                    
                
                FROM
                  TGFFIN FIN,
                  TGFPAR PAR,
                  TSIEMP EMP,
                  TGFNAT NAT
                
                WHERE FIN.CODPARC = PAR.CODPARC 
                  AND NAT.CODNAT=FIN.CODNAT 
                  AND FIN.CODEMP=EMP.CODEMP 
                  AND (TRUNC(FIN.DTNEG) <= :DATAREF OR (TRUNC(FIN.DTENTSAI) <= :DATAREF AND FIN.DTNEG IS NULL)) 
                  /* AND (TRUNC(FIN.DHMOV) <= :DATAREF) */
                   AND ((FIN.CODNAT <> 2010201) OR (FIN.CODNAT=2010201 AND FIN.DHMOV<=:DATAREF)) 
                  AND ( (FIN.AD_DTBAIXAREAL > = (TO_DATE(:DATAREF) + 1 )
                            AND
                            (SELECT MBC.CODCTABCOINT
                               FROM TGFMBC MBC
                              WHERE MBC.NUBCO=FIN.NUBCO) IN (1,15,16,18,25,26,48,49,50,53,60,68,71,72,73) 
                                AND FIN.NUBCO IS NOT NULL
                        ) 
                        OR
                        (   FIN.DHBAIXA >= (TO_DATE(:DATAREF) + 1) 
                            AND
                            (
                                (
                                    ( SELECT MBC.CODCTABCOINT
                                        FROM TGFMBC MBC
                                        WHERE MBC.NUBCO = FIN.NUBCO) NOT IN (1,15,16,18,25,26,48,49,50,53,60,68,71,72,73)
                                    ) OR FIN.NUBCO IS NULL
                                )
                            ) OR FIN.DHBAIXA IS NULL
                        ) 
                        AND FIN.DTNEG >= '31/12/2017' 
                        AND PAR.CLIENTE = 'S' 
                        AND FIN.PROVISAO='N' 
                        AND FIN.RECDESP=1 
                        AND (FIN.CODTIPOPER IN (SELECT TOP.CODTIPOPER
                                                  FROM TGFTOP TOP
                                                  WHERE TOP.TIPMOV='V'
                                                ) 
                                                OR FIN.CODTIPOPER in(1652,1654)
                            ) 
				AND (PAR.CODPARC IN (:CODPARC) OR :CODPARC IS NULL)
                GROUP BY
			    FIN.CODPARC,
                    PAR.RAZAOSOCIAL,
                    FIN.CODNAT,
                    NAT.DESCRNAT

					
), 

CONTABIL AS ( 

                SELECT
                    DD.CODCTACTB,
                    DD.DESCRCTA,  
                    SUM(DD.VALOR) AS VALOR_CONTABIL,
                    DD.CODPARC,
                    DD.RAZAOSOCIAL
                FROM
                    CONTABIL_AUX DD 
                WHERE 
                    DD.VALOR <> 0
			  
                GROUP BY
                    DD.CODCTACTB,
                    DD.DESCRCTA,  
                    DD.CODPARC,
                    DD.RAZAOSOCIAL

),

 

CONTABIL_AGRUP AS ( 

                SELECT

                    SUM(DD.VALOR) AS VALOR_CONTABIL,
                    DD.CODPARC
                FROM
                    CONTABIL_AUX DD 
                WHERE 
                    DD.VALOR <> 0
			  
                GROUP BY
                    DD.CODPARC

),
                    
FINANCEIRO AS(
                SELECT
                    DD.CODPARC AS CODPARC,
                    DD.RAZAOSOCIAL AS RAZAOSOCIAL,
                    DD.CODNAT,
                    DD.DESCRNAT,
                    SUM(DD.SOMA_VLRDESDOB) AS VALOR_FINANCEIRO
                    
                FROM
                    FINANCEIRO_AUX DD
			
                GROUP BY
                    DD.CODPARC,
                    DD.RAZAOSOCIAL,
                    DD.CODNAT,
                    DD.DESCRNAT



)

,
                    
FINANCEIRO_AGRUP AS(
                SELECT
                    DD.CODPARC,
                    SUM(DD.SOMA_VLRDESDOB) AS VALOR_FINANCEIRO
                    
                FROM
                    FINANCEIRO_AUX DD
			
                GROUP BY
                    DD.CODPARC

)

, DIF_CLIENTES AS (

					SELECT 

					CTB.CODPARC					   
					 
					FROM CONTABIL_AGRUP CTB JOIN FINANCEIRO_AGRUP FIN
					ON(CTB.CODPARC = FIN.CODPARC) 

					WHERE (NVL(CTB.VALOR_CONTABIL,0) - NVL(FIN.VALOR_FINANCEIRO,0)) <> 0

					)    

SELECT 
    NVL(CTB.CODPARC, FIN.CODPARC) as CODPAR_ORD,
    NVL(CTB.RAZAOSOCIAL,FIN.RAZAOSOCIAL) as RAZAOSOCIAL_ORD,
	CTB.CODCTACTB,
	CTB.DESCRCTA,  
	CTB.VALOR_CONTABIL,
	CTB.CODPARC,
	CTB.RAZAOSOCIAL,
	(NVL(CTB.VALOR_CONTABIL,0) - NVL(FIN.VALOR_FINANCEIRO,0)) AS DIFERENCA,
    FIN.CODNAT,
    FIN.DESCRNAT,
	FIN.VALOR_FINANCEIRO,
	FIN.CODPARC AS CODPARCF,
	FIN.RAZAOSOCIAL AS RAZAOSOCIALF

FROM CONTABIL CTB FULL JOIN FINANCEIRO FIN
ON(CTB.CODPARC = FIN.CODPARC
AND CTB.VALOR_CONTABIL = FIN.VALOR_FINANCEIRO)  

WHERE (NVL(:FILTRADIF,'N') = 'N')

UNION ALL

SELECT 
    NVL(CTB.CODPARC, FIN.CODPARC) as CODPAR_ORD,
    NVL(CTB.RAZAOSOCIAL,FIN.RAZAOSOCIAL) as RAZAOSOCIAL_ORD,
	CTB.CODCTACTB,
	CTB.DESCRCTA,  
	CTB.VALOR_CONTABIL,
	CTB.CODPARC,
	CTB.RAZAOSOCIAL,
	(NVL(CTB.VALOR_CONTABIL,0) - NVL(FIN.VALOR_FINANCEIRO,0)) AS DIFERENCA,
    FIN.CODNAT,
    FIN.DESCRNAT,
	FIN.VALOR_FINANCEIRO,
	FIN.CODPARC AS CODPARCF,
	FIN.RAZAOSOCIAL AS RAZAOSOCIALF
    
    
	

FROM CONTABIL CTB FULL JOIN FINANCEIRO FIN
ON (CTB.CODPARC = FIN.CODPARC 
AND CTB.VALOR_CONTABIL = FIN.VALOR_FINANCEIRO)

WHERE NVL(:FILTRADIF,'N') = 'S' 
  AND (EXISTS (SELECT 1 FROM  DIF_CLIENTES DIF
				WHERE DIF.CODPARC = CTB.CODPARC
				   OR DIF.CODPARC = FIN.CODPARC) 
				   
		OR  NVL(CTB.CODPARC,0) = 0

		OR 	NVL(FIN.CODPARC,0) = 0
		
		
		
		)
  AND (NVL(CTB.VALOR_CONTABIL,0) - NVL(FIN.VALOR_FINANCEIRO,0)) <> 0
												  
												  
    
ORDER BY  CODPAR_ORD, codparc, CODPARCF

sera aonde que esta o defeito??!?!?


           
	
	
