# Lab 5 - Multiple Linear Regression

- Due Jun 25 by 11:59pm
   - Points 5
   - Submitting a text entry box, a website url, a media recording, or a file upload

## Overview

In this lab, you will use the dataset you have been working with in your previous labs and apply the concepts of **multiple linear regression**.

The goal of this lab is not only to run a regression model in R. The goal is to understand what the model is doing, explain the results clearly, evaluate the model’s usefulness, and communicate the **“so what?”.**

---

## Data Requirement

You must use the dataset you have been working with in your previous labs.

Your dataset should include:

- One outcome variable, also called the dependent variable or response variable
- At least 5 explanatory variables, also called independent variables or predictors

Example:

```
Outcome variable: Sales
Predictor 1: Advertising Spend
Predictor 2: Price
Predictor 3: Customer Rating
```

---

# Required Sections

Your Quarto file must include the following sections.

---

## 1. Research Question

Write one clear research question your model is trying to answer.

Example:

```
How do advertising spend, price, and customer rating relate to product sales?
```

Your research question should make it clear:

- What outcome you are studying
- Which predictors you are using
- Why the question matters

Your question should be specific enough that a regression model can help answer it.

---

## 2. Dataset and Variables

Briefly describe your dataset.

Include:

- Where the data came from
- What each row represents
- How many observations are included
- Which variables you selected for the model

You must clearly identify:

```
Outcome variable:
Predictor variable 1:
Predictor variable 2:
Predictor variable 3:
```

For each variable, briefly explain what it represents.

Example:

```
Outcome variable: Sales
Sales represents the number of units sold for each product.
Predictor variable 1: Advertising Spend
Advertising spend represents the amount spent promoting each product.
Predictor variable 2: Price
Price represents the selling price of the product.
Predictor variable 3: Customer Rating
Customer rating represents the average review score for the product.
```

---

## 3. Write the Regression Model Equation

Before interpreting your results, you must write the equation for your multiple linear regression model.

The general form is:

```
Y = β0 + β1X1 + β2X2 + β3X3 + ε
```

Where:

```
Y = outcome variableβ0 = interceptβ1, β2, β3 = coefficients for each predictorX1, X2, X3 = predictor variablesε = error term
```

Then write your model using your own variable names.

Example:

```
Sales = β0 + β1(Advertising Spend) + β2(Price) + β3(Customer Rating) + ε
```

After running the model in R, also write the estimated model using your actual coefficient values.

Example:

```
Predicted Sales = 120.50 + 2.30(Advertising Spend) - 5.75(Price) + 18.20(Customer Rating)
```

This equation should come from your own regression output.

---

## 4. Run the Multiple Linear Regression Model in R

Use R to fit your model.

Example code:

```
model <- lm(outcome_variable ~ predictor_1 + predictor_2 + predictor_3, data = your_data)summary(model)
```

Your code should be clean, readable, and organized in your Quarto file.

You may need to clean or prepare your data before running the model. For example, you may need to remove missing values, rename variables, or select only the variables you need.

---

## 5. Interpret the Model Summary

You must interpret the regression summary in plain English.

Do not only paste the R output.

You must explain the following:

---

### A. Coefficients

For each predictor, explain what the coefficient means.

Use this sentence structure:

```
Holding the other variables constant, a one-unit increase in [predictor] is associated with a [increase/decrease] of [coefficient value] in [outcome variable].
```

Example:

```
Holding price and customer rating constant, a one-unit increase in advertising spend is associated with a 2.30-unit increase in predicted sales.
```

You should also explain whether the relationship is positive or negative.

A positive coefficient means that as the predictor increases, the predicted outcome increases.

A negative coefficient means that as the predictor increases, the predicted outcome decreases.

---

### B. P-values

Explain which predictors appear statistically significant and which do not.

You should answer:

```
Which predictors show evidence of a relationship with the outcome?Which predictors do not show strong evidence of a relationship? What does this mean in plain English?
```

Remember: a p-value does not tell us whether something is important in the real world. It only gives us evidence about whether the relationship is statistically different from zero, based on the data and model.

---

### C. R-squared

Interpret the R-squared value.

Use this sentence structure:

```
The R-squared value is [value], which means the model explains approximately [percent]% of the variation in [outcome variable].
```

Example:

```
The R-squared value is 0.64, which means the model explains approximately 64% of the variation in sales.
```

R-squared helps us understand how much of the variation in the outcome variable is explained by the predictors in the model.

---

### D. Adjusted R-squared

Interpret the adjusted R-squared value.

Adjusted R-squared is especially important in multiple linear regression because it accounts for the number of predictors in the model.

Use this idea:

```
Adjusted R-squared helps us understand whether adding more variables actually improves the model after accounting for model complexity.
```

You should compare R-squared and adjusted R-squared.

If adjusted R-squared is much lower than R-squared, it may mean that some predictors are not adding much value to the model.

---

## 6. Residual Errors and Model Fit

Your lab must clearly explain residuals.

A residual is the difference between the actual value and the predicted value.

```
Residual = Actual Value - Predicted Value
```

In plain English:

```
A residual tells us how far off the model’s prediction was for one observation.
```

Example:

```
If the actual sales value was 100 and the model predicted 90, the residual is 10. If the actual sales value was 100 and the model predicted 115, the residual is -15.
```

A positive residual means the model underpredicted.

A negative residual means the model overpredicted.

---

## 7. Residual Plot or Residual Output

You must include and explain at least one residual-related output or plot.

Option 1:

```
plot(model)
```

Option 2:

```
your_data$residuals <- residuals(model)your_data$predicted_values <- fitted(model)head(your_data)
```

Option 3:

```
library(ggplot2)your_data$residuals <- residuals(model)your_data$predicted_values <- fitted(model)ggplot(your_data, aes(x = predicted_values, y = residuals)) +  geom_point() +  geom_hline(yintercept = 0, linetype = "dashed") +  labs(    title = "Residuals vs. Predicted Values",    x = "Predicted Values",    y = "Residuals"  )
```

After including a residual plot or residual output, explain:

- What residuals are
- Whether the residuals seem randomly scattered
- Whether there are any obvious patterns
- Whether the model seems to overpredict or underpredict some values
- What residual errors tell us about the model’s limitations

Your model does not need to be perfect. The goal is to show that you understand what the errors mean.

---

## 8. Model Assumptions and Limitations

Briefly discuss whether your model seems reasonable.

You should comment on the following:

```
Linearity: Does the relationship between the predictors and outcome seem roughly linear? Residuals: Do the errors seem randomly scattered? Outliers: Are there any points that may strongly affect the model? Multicollinearity: Could any predictors be too closely related to each other? Causation: Can your model prove cause and effect?
```

Important reminder:

```
Regression can show relationships or associations, but it does not automatically prove causation.
```

You should be honest about what your model can and cannot tell us.

---

## 9. The “So What?” Interpretation

This is one of the most important parts of the lab.

Explain why your model matters.

Answer the following:

```
What did you learn from the model? Which predictors seem most important?How useful is the model? What real-world question, decision, or issue does this help us understand? What should someone be careful about when interpreting the results?
```

Your explanation should be written for a general audience, not only for someone who knows statistics.

Do not just say:

```
The model was significant.
```

Instead, explain what the model helps us understand.

Example:

```
This model helps us understand that advertising spend and customer rating may be useful predictors of sales, but price may not be as useful in this dataset. The R-squared value suggests that the model explains a meaningful amount of variation in sales, but the residual errors show that the model still makes mistakes. This means the model may be helpful for understanding general patterns, but it should not be used as a perfect prediction tool.
```

---

# Submission Requirements

You must submit:

```
1. Your Quarto code file: .qmd2. Your rendered PDF file: .pdf3. A 3-minute video explaining your “so what?” interpretation
```

---

## Video Requirement

You must record a video where your face is visible and you explain the **“so what?”** of your regression model.

The video must be exactly **3 minutes**.

You may not go over or under the 3-minute mark.

Your video should explain:

```
1. What question you studied
2. What variables you used
3. What the model found
4. What R-squared and adjusted R-squared tell us
5. What the residual errors tell us
6. Why the results matter
7. What limitations someone should keep in mind
```

Do not spend the video reading code line by line.

Focus on explaining the meaning of your model. Points will be deducted if you read a script. 

---

## Suggested 3-Minute Video Structure

Use this structure to stay on time:

```
0:00–0:30 Introduce your research question and dataset.
0:30–1:10 Explain your outcome variable and predictors.
1:10–1:50 Explain the main regression results, including important coefficients.
1:50–2:20 Explain R-squared, adjusted R-squared, and residual errors.
2:20–3:00 Explain the “so what?” and limitations.
```

Your video should be clear, concise, and professional.

---

---

# Grading Rubric

Total: **5 points**

QMD and PDF Submission — 3 points

3-Minute Video Explanation — 2 points

Remember:

```
Regression is not just about prediction. Regression is about understanding relationships, uncertainty, errors, and limitations.
```
