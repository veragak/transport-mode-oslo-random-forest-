
############################################################
# Load Libraries
############################################################
library(randomForest)
library(caret)
library(ggplot2)
library(patchwork)
library(kableExtra)
library(knitr)         # for kable()

############################################################
# Import and Clean Data
############################################################
load("TransportModeSweden.2526.RData")

# Inspection
str(data)
head(data)
summary(data)

# Convert numeric variables from comma to dot and then numeric
num_cols <- c("time_pt", "time_car", "time_ratio", "age")

for (col in num_cols) {
  data[[col]] <- as.numeric(gsub(",", ".", data[[col]]))
}

# Convert outcome variable to factor 
data$mode <- factor(
  data$mode,
  levels = c(0, 1),
  labels = c("Public transport", "Car")
)

# Convert dummy variables to factor
dummy_vars <- c(
  "one_transfer", "mult_transfer", "walk_500", "wait_5",
  "high_freq", "dist_20", "high_inc", "high_ed", "woman"
)

data[dummy_vars] <- lapply(data[dummy_vars], factor)

# Check and remove missing values (17 rows)
colSums(is.na(data))
data <- na.omit(data)

# Final check
str(data)
summary(data)

############################################################
# Train/test split
############################################################
set.seed(123)  # for reproducibility

index <- createDataPartition(data$mode, p = 0.7, list = FALSE)
train <- data[index, ]
test  <- data[-index, ]

############################################################
# Train a Random Forest
############################################################
set.seed(123)

rf_model <- randomForest(
  mode ~ .,       
  data       = train,
  ntree      = 500,
  importance = TRUE
)

rf_model

############################################################
# Predict on test set & performance
############################################################

# Confusion matrix (raw)
pred_test <- predict(rf_model, newdata = test)
cm <- confusionMatrix(pred_test, test$mode)

# Heatmap of confusion matrix
cm_data <- as.data.frame(cm$table)
colnames(cm_data) <- c("Predicted", "Actual", "Freq")

ggplot(cm_data, aes(Actual, Predicted, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), size = 3) +
  scale_fill_gradient(low = "lightblue", high = "steelblue") +
  labs(
    title = "Figure 1: Confusion Matrix Heatmap",
    x = "Actual Class",
    y = "Predicted Class"
  ) +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = 8),
    axis.title.y = element_text(size = 8),
    axis.text.x  = element_text(size = 7),
    axis.text.y  = element_text(size = 7),
    plot.title   = element_text(size = 10, face = "bold")
  )

# Train & test confusion matrices (Car as positive class)
pred_train <- predict(rf_model, newdata = train)
cm_train   <- confusionMatrix(pred_train, train$mode, positive = "Car")

pred_test  <- predict(rf_model, newdata = test)
cm_test    <- confusionMatrix(pred_test, test$mode, positive = "Car")

# Overall performance metrics
stats <- data.frame(
  `Train Accuracy`    = cm_train$overall["Accuracy"],
  `Test Accuracy`     = cm_test$overall["Accuracy"],
  Kappa               = cm_test$overall["Kappa"],
  Sensitivity         = cm_test$byClass["Sensitivity"],
  Specificity         = cm_test$byClass["Specificity"],
  `Balanced Accuracy` = cm_test$byClass["Balanced Accuracy"]
)

kable(stats, digits = 3,
      caption = "Performance Metrics for Random Forest") %>%
  kable_styling(full_width = FALSE, position = "center")

############################################################
# Global interpretation: variable importance
############################################################
varImpPlot(rf_model, type = 2,
           main = "Random forest variable importance")

imp        <- importance(rf_model, type = 2)  # MeanDecreaseGini
imp_sorted <- sort(imp[, "MeanDecreaseGini"], decreasing = TRUE)
imp_sorted

top4_names <- names(imp_sorted)[1:4]
top4_names

############################################################
# Global interpretation: partial dependence plots
# (effect of top 4 variables on P(choosing Car))
############################################################

get_pdp <- function(model, data, var, grid.size = 30) {
  stopifnot(var %in% names(data))
  
  x_vals <- seq(
    min(data[[var]], na.rm = TRUE),
    max(data[[var]], na.rm = TRUE),
    length.out = grid.size
  )
  
  tmp <- data
  pd  <- numeric(length(x_vals))
  
  for (i in seq_along(x_vals)) {
    tmp[[var]] <- x_vals[i]
    probs      <- predict(model, newdata = tmp, type = "prob")[, "Car"]
    pd[i]      <- mean(probs)
  }
  
  data.frame(x = x_vals, y = pd)
}

top_vars <- c("time_ratio", "time_car", "time_pt", "age")

pdp_list <- lapply(top_vars, function(v) {
  df_pdp <- get_pdp(rf_model, train, v)
  ggplot(df_pdp, aes(x = x, y = y)) +
    geom_line(color = "steelblue", size = 1) +
    labs(x = v, y = "Predicted P(Car)") +
    theme_minimal() +
    theme(
      axis.title.x = element_text(size = 8),
      axis.title.y = element_text(size = 8),
      axis.text.x  = element_text(size = 7),
      axis.text.y  = element_text(size = 7)
    )
})

((pdp_list[[1]] | pdp_list[[2]]) /
    (pdp_list[[3]] | pdp_list[[4]])) +
  patchwork::plot_annotation(title = "Figure 2: Partial Dependence of Top Predictors") &
  theme(plot.title = element_text(size = 10, face = "bold"))
