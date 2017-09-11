Write a SQL query using the professor / department / compensation data that outputs the average number of vacation days by department:

```
department_name                average_vacation_days
-----------------------------  ---------------------
Transfiguration                2.0
Defence Against the Dark Arts  9.0
Study of Ancient Runes         8.0
Care of Magical Creatures      13.0

```

Answer:

```sql
SELECT department.department_name, AVG(compensation.vacation_days) AS average_vacation_days
FROM department
JOIN professor ON department.id = professor.department_id
JOIN compensation ON professor.id = compensation.professor_id
GROUP BY department.department_name
ORDER BY average_vacation_days;

```
