-- Identify Workflow Types With a High Number of Concurrent Active Workflows
----------------------------------------------------------------------------
SELECT WorkflowTypeId, Name, ActiveWorkflows
FROM WorkflowType
   INNER JOIN (SELECT WorkflowTypeId, COUNT(*) AS ActiveWorkflows
                 FROM Workflow
                 WHERE CompletedDateTime IS NULL
                 GROUP BY WorkflowTypeId
   ) AS Workflows ON WorkflowTypeId = WorkflowType.Id
ORDER BY ActiveWorkflows DESC;

-- Identify Workflow Types With Longest Lifespan of Workflows
----------------------------------------------------------------------------
DECLARE @today DATETIME = GETDATE();
SELECT WorkflowTypeId, Name, ShortestLifespan, LongestLifespan, AverageLifespan, StandardDeviation
FROM WorkflowType
    INNER JOIN (SELECT WorkflowTypeId,
                MIN(Lifespan)          AS ShortestLifespan,
                MAX(Lifespan)          AS LongestLifespan,
                AVG(Lifespan)          AS AverageLifespan,
                MAX(StandardDeviation) AS StandardDeviation
        FROM (SELECT WorkflowTypeId, ActivatedDateTime, CompletedDate,
                DATEDIFF(DAY, ActivatedDateTime, CompletedDate) AS Lifespan,
                STDEV(DATEDIFF(DAY, ActivatedDateTime, CompletedDate)) OVER (PARTITION BY WorkflowTypeId) AS StandardDeviation
                FROM (SELECT WorkflowTypeId, ActivatedDateTime, 
                             IIF(CompletedDateTime IS NULL, @today, CompletedDateTime) AS CompletedDate
                FROM Workflow) AS Workflows) AS WorkflowLifespan
        GROUP BY WorkflowTypeId) AS WorkflowStats ON WorkflowTypeId = Id
ORDER BY AverageLifespan DESC;

-- Monitor the Process Workflows Job
----------------------------------------------------------------------------
SELECT ServiceJobId,
       Status,
       AVG(Elapsed)  AS AvgTimeToRun,
       MAX(Elapsed)  AS MaxTimeToRun,
       SUM(HadError) AS RunsWithError,
       COUNT(*)      AS Runs
FROM (SELECT ServiceJobId,
             Status,
             DATEDIFF(SECOND, StartDateTime, StopDateTime) AS Elapsed,
             IIF(StatusMessage LIKE '%error%', 1, 0)       AS HadError
      FROM ServiceJobHistory
      WHERE ServiceJobId = 8) AS JobHistory
GROUP BY ServiceJobId, Status;