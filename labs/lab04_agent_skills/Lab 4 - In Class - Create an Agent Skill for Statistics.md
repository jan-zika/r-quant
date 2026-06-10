# Lab 4 - In Class - Create an Agent Skill for Statistics

- Due Tuesday by 11:59pm
   - Points 3
   - Submitting a text entry box, a website url, or a file upload

## Overview

In this lab, your group will create an **Agent Skill** connected to something we have covered in class.

A skill is a folder with instructions that helps an AI agent complete a specific type of task. Your group will decide what statistical topic, problem, or process your skill should focus on.

This assignment is intentionally open-ended. The goal is for your group to think critically about how an AI agent should approach a statistical task, not just give the agent a simple prompt.

Your skill may focus on a concept, a method, a common mistake, a real-world problem, or a process used in statistics.

Examples include, but are not limited to:

```text
Descriptive statistics
Data visualization
Sampling and bias
Probability
Confidence intervals
Hypothesis testing
Comparing groups
Correlation
Regression
Interpreting results
Choosing the correct method
Using R for statistics
Writing a statistical explanation in Quarto
```

## Main Objective

By the end of this lab, your group should be able to answer:

**What statistical idea are we helping the agent understand, and how can we design a skill that helps the agent approach it responsibly?**

---

## Group Work

You will work in your pre-assigned groups.

Each group will create one skill and present it to the class.

Your group should decide:

```text
What topic should our skill focus on?
Why does this topic matter?
When would someone use this skill?
What should the agent do step by step?
What mistakes should the agent avoid?
How should the agent explain the result?
```

---

## Required Submission

Each group must submit:

```text
1. A skill folder
2. A SKILL.md file inside the skill folder
3. A sample .qmd file explaining the skill, showing the skill in action, and including the group reflection
```

Your folder should look like this:

```text
.agents/skills/
└── your-skill-name/
    └── SKILL.md
```

You will also submit a sample Quarto file:

```text
your-skill-demo.qmd
```

The `.qmd` file is what your group will use to present your work to the class.

---

## Part 1: Create the Skill Folder

Create a folder for your skill.

The folder name should be lowercase and use hyphens instead of spaces.

Examples:

```text
sampling-bias-checker
hypothesis-test-helper
correlation-vs-causation
data-visualization-guide
descriptive-statistics-helper
r-statistics-explainer
```

These are only examples. Your group may create a different skill.

---

## Part 2: Create the `SKILL.md` File

Inside your skill folder, create a file called:

```text
SKILL.md
```

Your `SKILL.md` file must include frontmatter at the top.

Use this basic structure:

```markdown
---
name: your-skill-name
description: Helps the agent work through a statistics-related task. Use when the user needs help with [your topic].
---

# Skill Title

## Purpose

Explain what this skill helps the agent do.

## When to Use This Skill

Describe when this skill should be used.

## Statistical Focus

Explain what statistical concept, method, or issue this skill focuses on.

## Instructions for the Agent

Tell the agent what steps it should follow.

## Common Mistakes to Avoid

List the mistakes the agent should avoid.

## Final Output Expectations

Explain what the agent should produce when using this skill.

## Example Use Case

Give one short example of how someone could use this skill.
```

Your skill does not need to be long. It needs to be clear and useful.

---

## Part 3: Create a Sample `.qmd` File

Create a sample Quarto file that explains your skill and shows it in action.

Name it something like:

```text
your-skill-demo.qmd
```

Your `.qmd` file should include:

```markdown
---
title: "Agent Skill Demo"
author: "Group Names"
format: html
---

## Skill Name

Write the name of your skill.

## What Our Skill Does

Explain what the skill is designed to help with.

## Why We Chose This Topic

Explain why your group chose this statistical topic or problem.

## How the Skill Works

Briefly explain the steps your skill tells the agent to follow.

## Example Prompt

Write one example prompt someone could ask the agent.

## Example Agent Response

Show a short example of what a good agent response might look like.

## Skill in Action

Use this section to show how the skill could help someone think through the topic.

This may include a short explanation, a small example, a table, a chart, or a few lines of R code.

## Group Reflection

Answer the following:

1. What did your group create?
2. How does this connect to statistics?
3. What mistake does your skill help prevent?
4. How could this skill help someone understand data better?
```

Your `.qmd` file does not need to be advanced. It should be clear enough for your group to use during the class presentation.

---

## Presentation

Each group will briefly present its skill to the class.

Your presentation should cover:

```text
1. The name of your skill
2. The topic it focuses on
3. Why your group chose that topic
4. When someone would use the skill
5. One example of the skill in action
6. What your group learned
```

You may use your `.qmd` file as your presentation guide.

---

## Grading Rubric

Total: 3 points

### 1. Skill Folder and `SKILL.md` File — 1 point

```text
1 point: Skill folder is created correctly and includes a clear SKILL.md file.
0.5 points: Skill folder or SKILL.md is incomplete or missing important parts.
0 points: Skill folder or SKILL.md is missing.
```

### 2. Statistical Connection and Critical Thinking — 1 point

```text
1 point: Skill clearly connects to a statistical topic and shows thoughtful reasoning.
0.5 points: Skill connects to statistics but is too general or unclear.
0 points: Skill does not clearly connect to statistics.
```

### 3. Sample `.qmd` File and Presentation Reflection — 1 point

```text
1 point: The .qmd file explains the skill, shows it in action, and includes the group reflection.
0.5 points: The .qmd file is incomplete or does not clearly show the skill in action.
0 points: The .qmd file is missing.
```

---

## Time Expectation

This lab is designed to be completed in approximately **30–45 minutes**.

Suggested time breakdown:

```text
5 minutes: Choose your topic
10 minutes: Create the skill folder and SKILL.md
15 minutes: Create the sample .qmd file
5–10 minutes: Prepare your short presentation
```

---

## Important Reminder

This assignment is not about creating the most advanced AI skill.

It is about showing that your group can think clearly about a statistical topic and explain how an AI agent should approach it.

A strong skill should help the agent:

```text
Ask better questions
Follow a clear process
Avoid common mistakes
Explain results clearly
Connect statistics to real-world thinking
```
