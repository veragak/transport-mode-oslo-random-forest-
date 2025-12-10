# Transport Mode Choice in the Oslo Region – Random Forest Analysis

This repository contains an individual assignment for the course **FEM11152 – Data Science for Marketing Analytics**.  
The goal is to model commuters’ choice between **car** and **public transport** in the Oslo region using a **random forest classifier**, and to interpret which factors drive this decision.

---

## Project Structure

`transport-mode-oslo-random-forest/`
- `data/`
  - TransportModeSweden.2526.RData       
- `R/`
  - 01_random_forest_transport_mode.R    # main analysis script
- `report/`
  - IndividualAssignment.Rmd             # report source (R Markdown)
  - IndividualAssignment.pdf             # final rendered report
- `figures/`
  - confusion_matrix_heatmap.png         # Figure 1 (optional export)
  - pdp_top_predictors.png               # Figure 2 (optional export)
- `README.md`

## Data Description

The dataset **`TransportModeSweden.2526.RData`** contains observations on daily commuting trips for individuals in the Oslo region, including:

- **mode**: chosen mode of transportation (0 = public transport, 1 = car)
- **time_pt**: public transport travel time (minutes)
- **time_car**: car travel time (minutes)
- **time_ratio**: `time_pt / time_car`
- **one_transfer**, **mult_transfer**: dummies for one or multiple transfers
- **walk_500**: dummy for walking distance to nearest stop > 500m
- **wait_5**: dummy for waiting time > 5 minutes during interchange
- **high_freq**: dummy for > 8 departures per hour
- **dist_20**: dummy for distance > 20 km
- **high_inc**, **high_ed**, **woman**: socio-demographic variables
- **age**: age of the individual

---

## Methods

The analysis focuses on:

- **Random forest classifier** (`randomForest` package) to predict transport mode (`mode`)
- **Train–test split**: 70% training, 30% test (stratified by mode)
- **Model evaluation** using:
  - Accuracy  
  - Balanced accuracy  
  - Sensitivity and specificity  
  - Confusion matrix (test set)

- **Global interpretation** of the black-box model using:
  - Variable importance (Mean Decrease in Gini)
  - Partial Dependence Plots (PDPs) for the four most important variables:  
    **`time_ratio`, `time_car`, `time_pt`, `age`**

---

## Key Findings

- **Relative travel time (`time_ratio`)** is the dominant driver: commuters strongly prefer the car when public transport is substantially slower.
- **Longer car travel times** reduce the likelihood of choosing the car, while **longer public transport times** increase it.
- **Age** has a small positive effect on car use: older commuters are more likely to drive.
- The model achieves **high predictive performance**, but classification is stronger for car users due to class imbalance.

---

## Reproducibility

To reproduce the analysis:

1. Open `report/IndividualAssignment.Rmd` in **RStudio**.
2. Install required packages:

   ```r
   install.packages(c("randomForest", "caret", "ggplot2", "patchwork", "kableExtra"))
    ```
3. Place TransportModeSweden.2526.RData in the data/ folder.
4. Knit the R Markdown file to PDF (or run R/random_forest_transport_mode.R line by line).

---

## Author

- Name: Vera Gak Anagrova
- Course: FEM11152 – Data Science for Marketing Analytics
- Institution: Erasmus School of Economics
