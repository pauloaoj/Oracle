/* Formatted on 08/04/2022 15:06:54 (QP5 v5.336) */
  SELECT DISTINCT CODPROD                                          AS CODIGO,
                  DESCRPROD                                        AS PRODUTO,
                  DESCRGRUPOPROD                                   AS GRUPO,
                  AVG (ROUND ((VR_UNITARIO + VLRIPI + ST), 2))     AS PRECO,
                  AVG (ROUND (VLRICMS, 2))                         AS ICMS,
                  AVG (ROUND (ST, 2))                              AS ST,
                  AVG (ROUND (VLRIPI, 2))                          AS IPI,
                  AVG (ROUND (VLR_PIS, 2))                         AS PIS,
                  AVG (ROUND (COFINS, 2))                          AS COFINS,
                  AVG (VLR_FEM_ICMS_ST + VLR_FEM_ICMS_OP)          AS FEM,
                  AVG (COMISSAO),
                  AVG (ROUND (CUSTO, 2))                           AS CUSTO
    FROM (SELECT DISTINCT
                 ITE.CODPROD,
                 PRO.DESCRPROD,
                 0.17
                     AS COMISSAO,
                 ITE.QTDNEG,
                 ROUND ((ITE.VLRUNIT * VOL.QUANTIDADE), 2)
                     AS VR_UNITARIO,
                 ITE.AD_CODTAB,
                 SANKHYA.FC_QTDALT (ITE.CODPROD, ITE.QTDNEG, ITE.CODVOL)
                     AS PC,
                 ITE.VLRTOT,
                 ITE.VLRIPI,
                 ITE.VLRICMS,
                 (SELECT SUM (DIN.VALOR)
                    FROM TGFDIN DIN
                   WHERE     DIN.NUNOTA = ITE.NUNOTA
                         AND DIN.SEQUENCIA = ITE.SEQUENCIA
                         AND DIN.CODIMP = 6)
                     AS VLR_PIS,
                 (SELECT SUM (DIN.VALOR)
                    FROM TGFDIN DIN
                   WHERE     DIN.NUNOTA = ITE.NUNOTA
                         AND DIN.SEQUENCIA = ITE.SEQUENCIA
                         AND DIN.CODIMP = 7)
                     AS COFINS,
                 NVL (
                     (SELECT SUM (DIN.VALOR)
                        FROM TGFDIN DIN
                       WHERE     DIN.NUNOTA = ITE.NUNOTA
                             AND DIN.SEQUENCIA = ITE.SEQUENCIA
                             AND DIN.CODIMP = 2),
                     0)
                     AS ST,
                 (SELECT SUM (DIN.VLRFCPINT)
                    FROM TGFDIN DIN
                   WHERE     DIN.NUNOTA = ITE.NUNOTA
                         AND DIN.SEQUENCIA = ITE.SEQUENCIA
                         AND DIN.CODIMP = 2)
                     AS VLR_FEM_ICMS_ST,
                 (SELECT SUM (DIN.VLRFCPINT)
                    FROM TGFDIN DIN
                   WHERE     DIN.NUNOTA = ITE.NUNOTA
                         AND DIN.SEQUENCIA = ITE.SEQUENCIA
                         AND DIN.CODIMP = 1)
                     AS VLR_FEM_ICMS_OP,
                 GRU.DESCRGRUPOPROD,
                 NVL (
                     (  SELECT MAX (CUS.ENTRADACOMICMS * FAT1.QUANTIDADE)    AS CUSTO_MEDIO
                          FROM TGFCUSITE CUS, TGFPRO PRO1, TGFVOA FAT1
                         WHERE     CUS.CODPROD = ITE.CODPROD
                               AND CUS.CODPROD = FAT1.CODPROD
                               AND CUS.CODPROD = ITE.CODPROD
                               AND FAT1.DIVIDEMULTIPLICA = 'M'
                               AND CUS.DTATUAL BETWEEN :1 AND :2
                      GROUP BY CUS.CODPROD),
                     0)
                     AS CUSTO
            FROM TGFCAB CAB,
                 TGFITE ITE,
                 TGFPRO PRO,
                 TGFPAR PAR,
                 TGFTOP TPO,
                 TGFGRU GRU,
                 TSICID CID,
                 TSIUFS UF,
                 TGFDIN DIN,
                 TGFVOA VOL
           WHERE     DIN.NUNOTA = ITE.NUNOTA
                 AND DIN.SEQUENCIA = ITE.SEQUENCIA
                 AND CAB.NUNOTA = ITE.NUNOTA
                 AND ITE.CODPROD = PRO.CODPROD
                 AND ITE.CODPROD = VOL.CODPROD
                 AND VOL.DIVIDEMULTIPLICA = 'M'
                 AND CAB.CODPARC = PAR.CODPARC
                 AND CAB.CODTIPOPER = TPO.CODTIPOPER
                 AND CAB.DHTIPOPER = TPO.DHALTER
                 AND PRO.CODGRUPOPROD = GRU.CODGRUPOPROD
                 AND PAR.CODCID = CID.CODCID
                 AND CID.UF = UF.CODUF
                 AND CAB.TIPMOV = 'V'
                 AND CAB.STATUSNFE = 'A'
                 AND SANKHYA.FC_QTDALT (ITE.CODPROD, ITE.QTDNEG, ITE.CODVOL) =
                     1
                 AND CAB.DTNEG BETWEEN :3 AND :4) V
GROUP BY CODPROD, DESCRPROD, DESCRGRUPOPROD
ORDER BY 1



/* Formatted on 08/04/2022 15:07:06 (QP5 v5.336) */
SELECT DIVIDEMULTIPLICA, QUANTIDADE
  FROM TGFVOA
 WHERE CODVOL = :B2 AND CODPROD = :B1