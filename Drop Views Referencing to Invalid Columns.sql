SET NOCOUNT ON;
--Views Referencing to invalid columns
DECLARE curView CURSOR FOR
    SELECT
		QUOTENAME(s.name) + '.' + QUOTENAME(v.name) AS ViewName
    FROM sys.views v
		INNER JOIN sys.schemas AS s ON v.schema_id = s.schema_id
    INNER JOIN sys.sql_modules m
        on v.object_id = m.object_id
	ORDER BY ViewName


OPEN curView
DECLARE @viewName SYSNAME

DECLARE @failedViews TABLE
(
	Rowid SMALLINT IDENTITY(1,1) NOT NULL,
    FailedViewName SYSNAME NOT NULL,
    ErrorMessage VARCHAR(MAX) NOT NULL,
	SQLstring NVARCHAR(512) NULL
)

FETCH NEXT FROM curView 
    INTO @ViewName

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC ('SELECT * INTO #temp FROM ' + @viewName + ' WHERE 1=0' )
    END TRY
    BEGIN CATCH
        INSERT INTO @failedViews (FailedViewName, ErrorMessage) VALUES (@viewName, ERROR_MESSAGE())
    END CATCH
    FETCH NEXT FROM curView 
        INTO @ViewName
END
CLOSE curView;
DEALLOCATE curView;


DECLARE @SQLstring NVARCHAR(256)
	, @MaxRowId SMALLINT
	, @RowId SMALLINT = 1;

SELECT @MaxRowId = MAX(RowId)
FROM @failedViews;

IF @MaxRowId > 0
	BEGIN
		UPDATE @failedViews
		SET SQLstring = 'DROP VIEW IF EXISTS ' + FailedViewName + ';';
	END

--SELECT * FROM @failedViews

WHILE @RowId <= @MaxRowId
	BEGIN
		SELECT @SQLstring = SQLstring
		FROM	@failedViews
		WHERE	RowId = @RowId;

		PRINT (@SQLstring);
		--EXEC sp_executesql @stmt = @SQLstring;

		SET @RowId = @RowId + 1;
	END
