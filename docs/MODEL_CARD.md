# Model card: Sahel Crop Recommender (v0.1)

Last updated: November 2026. Code: MIT. Author: Abdulkadir Omobolarin Yusuf.

## What the models are

- 16 LightGBM regressors, one per crop (sorghum, pearl millet, cowpea, groundnut, maize, rice, cassava, cotton, yams, sesame, onion, soybean, tomato, dry bean, sweet potato, sugarcane).
- Target: the crop's share of harvested area in a SPAM 2020 v2.2 pixel (about 9 km), from 0 to 1. Cross-entropy objective, 300 trees, 31 leaves, learning rate 0.05, fixed seed.
- Inputs: 51 environment features (23 climate, 18 soil, 5 terrain, 5 salinity). Sentinel and MODIS features were tested and add nothing.
- Training: 21,128 pixels. Evaluation: spatial cross-validation in 100 km blocks, so every score is out of fold.
- Size: 7.8 MB for all 16 models.
- Output: a predicted share per crop, used to rank crops. A relative score (predicted share divided by the crop's mean share) is also computed. Which of the two is used for the final ranking is not decided yet.

## Intended use

- Exploring which of the 16 crops are environmentally associated with a location in the dryland cropland of Senegal, Gambia, Mauritania, Mali, Burkina Faso, Niger, Nigeria, Chad and Cameroon.
- Teaching, research and portfolio demonstration, and as one input for people who already have local agronomic knowledge.

## Not intended for

- Farm-level advice, or any decision without local agronomic advice.
- Predicting yield, profit, or food security.
- Locations outside the grid: outside the nine countries, under 5% cropland, or aridity index of 0.65 or above (for example the humid south of Nigeria and Cameroon).
- Crops outside the list of 16: date palm, tree crops, fonio, Bambara groundnut, other vegetables.
- Planning irrigation. Rice, onion and tomato depend on water access that the models do not see.
- Future climate. Climate inputs are 1991 to 2020 normals and no climate-change scenario was tested.
- Ranking crops by nutrition. Nutrition values are shown next to a recommendation and never change the ranking.

## Training and evaluation data

- Labels: SPAM 2020 v2.2, a modelled product that downscales subnational statistics (CC BY-SA 4.0). It describes what is grown, which is shaped by markets, habits and seed supply, not only by environmental fit. Part of its signal may come from GAEZ, one of its own inputs.
- Independent field checks: CropHarvest points (Burkina Faso, Mali, Senegal; 93 pixels), Niger EHCVM 2018-19 (297 pixels), Nigeria GHS-Panel 2018-19 (135 pixels). Statistics are computed per SPAM pixel, not per point. Observation years (2017 to 2022) differ from SPAM's 2019 to 2021, and survey locations are anonymised or offset.

## Performance (out of fold)

| Measure | LightGBM | Random forest | Country-mean baseline |
|---|---|---|---|
| Mean rank correlation with SPAM | 0.675 | 0.644 | 0.454 |
| Top-5 overlap with SPAM | 0.794 | 0.789 | 0.718 |
| Top-1 match with SPAM | 0.590 | 0.591 | 0.364 |
| Survey presence AUC, mean (crop-countries with interval above 0.5) | 0.658 (12 of 18) | 0.674 (13 of 18) | not applicable |
| CropHarvest top-5 hit rate (chance 0.31) | 0.765 | 0.765 | 0.799 |

The two model families cannot be told apart on field data. In Burkina Faso, Mali and Senegal neither beats the country mean, because country-level patterns are already built into SPAM.

## Reliability per crop

SPAM columns are LightGBM, environment only. "Skill" means the bootstrap interval of the survey presence AUC is above 0.5.

| Crop | SPAM rank corr | SPAM R2 | Field evidence | Confidence |
|---|---|---|---|---|
| Sorghum | 0.66 | 0.50 | Niger AUC 0.78 (skill); CropHarvest top-5 1.00 | Good |
| Pearl millet | 0.78 | 0.61 | Nigeria AUC 0.84 (skill) | Good |
| Groundnut | 0.71 | 0.46 | Niger 0.68, Nigeria 0.67 (skill in both) | Good |
| Cowpea | 0.78 | 0.58 | Niger 0.84 (skill); Nigeria 0.62 (no skill) | Moderate |
| Maize | 0.79 | 0.59 | Niger 0.66 (no skill); Nigeria 0.64 (skill) | Moderate |
| Rice | 0.62 | 0.26 | Niger 0.63, Nigeria 0.62 (skill); poorly placed in CropHarvest (top-5 0.06 to 0.17); irrigation-dependent | Moderate, needs the water-access input |
| Cassava | 0.68 | 0.46 | Niger 0.80 (skill); Nigeria 0.49 (no skill) | Moderate |
| Sesame | 0.62 | 0.28 | Niger 0.68 (skill); Nigeria 0.47 (no skill) | Moderate |
| Cotton | 0.63 | 0.44 | No survey data; CropHarvest 14 pixels, indicative only | Moderate (SPAM only) |
| Dry bean | 0.74 | 0.57 | No field data; mostly explained by country means | Moderate (SPAM only) |
| Yams | 0.66 | 0.36 | No field validation (households 43 km or more from the grid) | Low |
| Onion | 0.64 | 0.17 | Niger 0.57, Nigeria 0.46 (no skill) | Low |
| Soybean | 0.79 | 0.19 | Nigeria 0.71 (skill); rarely reaches the top 5 by raw score | Low |
| Tomato | 0.76 | 0.11 | Niger 0.69 (borderline) | Low |
| Sweet potato | 0.67 | 0.29 | Too few sites to evaluate | Low |
| Sugarcane | 0.29 | 0.02 | Too few sites to evaluate | Low |

Treat "Low" crops as indicative only. Their explanations are especially weak.

## Known limitations

- Rare crops (soybean, tomato, sweet potato, sugarcane) have tiny shares everywhere, so raw predicted shares almost never put them in the top 5. The relative score helps them but lowers hit rates for the five most common crops (CropHarvest 0.95 to 0.74).
- EcoCrop limits reduced agreement with SPAM and survey AUC when used as a score, so they are used only as feasibility flags, not as a ranking term.
- Validation is uneven: no field data for Chad, Cameroon, Mauritania or Gambia.
- Explanations (SHAP) describe the model, not agronomic causes. Solar radiation is the top feature for 10 crops, but its direction flips between crops, which shows it acts as a north-south gradient. Bulk density and elevation probably act as geographic proxies in the same way.
- Correlated features (35 pairs with |r| above 0.95) share SHAP credit, so family-level shares are more reliable than single features.
- About 0.26% of grid cells have no SPAM label.

## Ethical considerations

A ranking presented as advice could steer farmers wrongly, especially for the Low-confidence crops or for rice without water access. Because labels reflect current practice, the models may reinforce what is already grown and not reveal better options. Use with local expertise.

## Licences and citation

Code is MIT. Models and figures derive from SPAM and CropHarvest (CC BY-SA 4.0) and are released under CC BY-SA 4.0. Nutrition data (WAFCT, CC BY-NC-SA 3.0 IGO) are kept separate. Sources and citations: [data_sources.md](data_sources.md).
