use insankaynaklari
go
--1 her aþama kaç aday ulaþtý?
SELECT
    COUNT(*)                                                        AS Toplam_Basvuru,
    SUM(CASE WHEN CV_Incelemesi_Tarihi IS NOT NULL THEN 1 END)      AS CV_Incelemesi,
    SUM(CASE WHEN _1_Mulakat_Tarihi    IS NOT NULL THEN 1 END)      AS Mulakat_1,
    SUM(CASE WHEN _2_Mulakat_Tarihi    IS NOT NULL THEN 1 END)      AS Mulakat_2,
    SUM(CASE WHEN Teklif_Tarihi        IS NOT NULL THEN 1 END)      AS Teklif,
    SUM(CASE WHEN Ise_Alim_Tarihi      IS NOT NULL THEN 1 END)      AS Ise_Alim
FROM dbo.recruitment_funnel;
GO
-- Departman bazlý basvurudan ise alým
Select 
	Departman,
	Count(*)	AS Toplam_Basvuru,
	Sum(Case When Ise_Alindi_Mi = 'Evet' THEN 1 ELSE 0 END)	AS Ise_Alinan,
	CAST(
		100.0 * SUM(CASE WHEN Ise_Alindi_Mi = 'Evet' THEN 1 ELSE 0 END)
		/ COUNT(*) AS DECÝMAL(5,1)
	)		AS Donusum_Orani_Yuzde
From dbo.recruitment_funnel
Group BY Departman
Order BY Donusum_Orani_Yuzde DESC;
go

-- Basvuru Kaynagi Bazli Basari Orani

Select
    Basvuru_Kaynagi,
    COUNT(*)                                                        AS Toplam_Basvuru,
    SUM(CASE WHEN Ise_Alindi_Mi = 'Evet' THEN 1 ELSE 0 END)         AS Ise_Alinan,
    CAST(
        100.0 * SUM(CASE WHEN Ise_Alindi_Mi = 'Evet' THEN 1 ELSE 0 END)
        / COUNT(*) AS DECIMAL(5,1)
    )                                                                AS Basari_Orani_Yuzde
FROM dbo.recruitment_funnel
GROUP BY Basvuru_Kaynagi
ORDER BY Basari_Orani_Yuzde DESC;
GO

-- Ortalama Surec Suresi ise alinan departman bazli basvuru kaynagi
SELECT
    Departman,
    COUNT(*)                        AS Ise_Alinan_Sayisi,
    AVG(Surec_Suresi_Gun * 1.0)     AS Ortalama_Sure_Gun,
    MIN(Surec_Suresi_Gun)           AS En_Kisa_Sure,
    MAX(Surec_Suresi_Gun)           AS En_Uzun_Sure
FROM dbo.recruitment_funnel
WHERE Ise_Alindi_Mi = 'Evet'
GROUP BY Departman
ORDER BY Ortalama_Sure_Gun ASC;
GO

-- aylik basvuru ve ise alým trendi
SELECT
    FORMAT(Basvuru_Tarihi, 'yyyy-MM')                               AS Basvuru_Ayi,
    COUNT(*)                                                        AS Basvuru_Sayisi,
    SUM(CASE WHEN Ise_Alindi_Mi = 'Evet' THEN 1 ELSE 0 END)         AS Ise_Alim_Sayisi
FROM dbo.recruitment_funnel
GROUP BY FORMAT(Basvuru_Tarihi, 'yyyy-MM')
ORDER BY Basvuru_Ayi;
GO

-- asama bazli kayip oraný(drop-off)
WITH AsamaSayilari AS (
    SELECT
        COUNT(*)                                                    AS Basvuru,
        SUM(CASE WHEN CV_Incelemesi_Tarihi IS NOT NULL THEN 1 END)  AS CV_Incelemesi,
        SUM(CASE WHEN _1_Mulakat_Tarihi    IS NOT NULL THEN 1 END)  AS Mulakat_1,
        SUM(CASE WHEN _2_Mulakat_Tarihi    IS NOT NULL THEN 1 END)  AS Mulakat_2,
        SUM(CASE WHEN Teklif_Tarihi        IS NOT NULL THEN 1 END)  AS Teklif,
        SUM(CASE WHEN Ise_Alim_Tarihi      IS NOT NULL THEN 1 END)  AS Ise_Alim
    FROM dbo.recruitment_funnel
)
SELECT
    'Basvuru -> CV Incelemesi'   AS Asama_Gecisi,
    CAST(100.0 * (Basvuru - CV_Incelemesi) / Basvuru AS DECIMAL(5,1)) AS Kayip_Orani_Yuzde
FROM AsamaSayilari
UNION ALL
SELECT 'CV Incelemesi -> 1. Mulakat',
    CAST(100.0 * (CV_Incelemesi - Mulakat_1) / NULLIF(CV_Incelemesi,0) AS DECIMAL(5,1))
FROM AsamaSayilari
UNION ALL
SELECT '1. Mulakat -> 2. Mulakat',
    CAST(100.0 * (Mulakat_1 - Mulakat_2) / NULLIF(Mulakat_1,0) AS DECIMAL(5,1))
FROM AsamaSayilari
UNION ALL
SELECT '2. Mulakat -> Teklif',
    CAST(100.0 * (Mulakat_2 - Teklif) / NULLIF(Mulakat_2,0) AS DECIMAL(5,1))
FROM AsamaSayilari
UNION ALL
SELECT 'Teklif -> Ise Alim',
    CAST(100.0 * (Teklif - Ise_Alim) / NULLIF(Teklif,0) AS DECIMAL(5,1))
FROM AsamaSayilari;
GO