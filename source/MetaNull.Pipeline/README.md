# Pipeline

Pipelines permits the definion of series of tasks

- A pipeline is divided in Stages
- Sages are devided in jobs
- Jobs are made of Steps
- Steps are made of tasks
- Where each task is an indivudal command to execute.

A pipeline shall contain at least 1 stage, containing at least 1 job, containing at least 1 step, containing at least 1 task.

Pipeline
+-- Stage
    +-- Job
        +-- Task