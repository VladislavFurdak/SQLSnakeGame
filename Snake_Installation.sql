   -- ,'._,`.
   --  (-.___.-)
   --  (-.___.-)
   --  `-.___.-'                  
   --   ((  @ @|              .            __
   --    \   ` |         ,\   |`.    @|   |  |      _.-._
   --   __`.`=-=mm===mm:: |   | |`.   |   |  |    ,'=` '=`.
   --  (    `-'|:/  /:/  `/  @| | |   |, @| @|   /---)W(---\
   --   \ \   / /  / /         @| |   '         (----| |----) ,~
   --   |\ \ / /| / /            @|              \---| |---/  |
   --   | \ V /||/ /                              `.-| |-,'   |
   --   |  `-' |V /                                 \| |/    @'
   --   |    , |-'                                 __| |__
   --   |    .;: _,-.                         ,--""..| |..""--.
   --   ;;:::' "    )                        (`--::__|_|__::--')
   -- ,-"      _,  /                          \`--...___...--'/   
   --(    -:--'/  /                           /`--...___...--'\
   -- "-._  `"'._/                           /`---...___...---'\
   --     "-._   "---.                      (`---....___....---')
   --      .' ",._ ,' )                     |`---....___....---'|
   --      /`._|  `|  |                     (`---....___....---') 
   --     (   \    |  /                      \`---...___...---'/
   --      `.  `,  ^""                        `:--...___...--;'
   --        `.,'               hh              `-._______.-'
   -- T-SQL Snake 1.0 
   -- Vladislav Furdak 2016
   
if db_id('SnakeDB') is not null
begin
	use master;
	alter database SnakeDB set single_user with rollback immediate
	DROP DATABASE SnakeDB
end

CREATE DATABASE SnakeDB;
use SnakeDB;
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Snake')
begin
EXEC('CREATE SCHEMA Snake')
end
GO

create procedure Snake.CreateField
@width AS int,
@height AS int
AS
begin
SET NOCOUNT ON;
	CREATE TABLE Snake.Field
	(
		X int NOT NULL ,
		Y int NOT NULL ,
		[State] int NOT NULL default(1),
		CONSTRAINT CheckCorrectStateCode CHECK ([State] in (1,2,3)),
		CONSTRAINT XY_PK PRIMARY KEY (X,Y)
	 )
	 
	 declare @countW int = 1;
	 declare @countH int =1;
	 
	 while (@countW <= @width)
	 begin
		while (@countH <= @height)
		begin
			insert into Snake.Field(X,Y,[State]) values(@countW,@countH,1)
			set @countH = @countH +1;
		end
		set @countW = @countW +1;
		set @countH = 1;
	 end
	 
return;
end
go

create procedure Snake.CreateScoreTable
as
begin
create table Snake.Score(
	Id int IDENTITY(1,1) Primary key,
	Name nvarchar(100),
	Achived int,
	Date datetime2,
	IsLost bit DEFAULT(0)
)
end
go

create procedure Snake.Initname(
	@UserName nvarchar(100),
	@UserId int OUT
)
as
begin
	insert into Snake.Score(Name) values(@UserName)
	set @UserId = SCOPE_IDENTITY();
end
go

create procedure Snake.CreateSnake(
@ScoreId as int,
@StartX as int,
@StartY as int)
as
begin
SET NOCOUNT ON;
	create table Snake.Snake(
		Id int IDENTITY(1,1) PRIMARY KEY,
		X int,
		Y int,
		IsHead bit DEFAULT(0),
		ParentId int NULL,
		ScoreId int NOT NULL,
		CONSTRAINT HaveParentConstraint FOREIGN KEY(ParentId) REFERENCES Snake.Snake (Id),
		CONSTRAINT ScoreIdFK FOREIGN KEY(ScoreId) REFERENCES Snake.Score(Id)
	)
	insert into Snake.Snake(x,y,IsHead,ScoreId) values(@StartX,@StartY, 1, @ScoreId)
	end
	go
	
create procedure Snake.RandomX(@output as int OUT)
as
begin
	declare @successAttempt bit = 0;
	declare @FieldSizeX int = (select max(X) from Snake.Field);
	declare @try int = -1;
	
	while(@successAttempt <> 1)
	begin
		set @try  = (SELECT FLOOR(RAND()*(@FieldSizeX-1)+1));
		set @successAttempt = (select 
				case when COUNT(*) > 0 then 0 else 1 end 
				from Snake.Snake s where s.X = @try);
	end
	set @output = @try;
end
go

create procedure Snake.RandomY(@output as int OUT)
as
begin
	declare @successAttempt bit = 0;
	declare @FieldSizeY int = (select max(Y) from Snake.Field);
	declare @try int = -1;
	
	while(@successAttempt <> 1)
	begin
		set @try  = (SELECT FLOOR(RAND()*(@FieldSizeY-1)+1));
		set @successAttempt = (select 
				case when COUNT(*) > 0 then 0 else 1 end 
				from Snake.Snake s where s.Y = @try);
	end
	set @output = @try;
end
go

create procedure Snake.Lost
as
begin
 SET NOCOUNT ON;
 declare @lastScore int = (select top(1) Id from Snake.Score order by Id desc) 
 declare @name nvarchar(100)= (select top(1) Name from Snake.Score order by Id desc)
  
 declare @score int = (select COUNT(*) from Snake.Snake
 where ScoreId = @lastScore)
 
 update Snake.Score set
 IsLost = 1
 
 PRINT 'Good game, '+@name+' but you lost, your score is '+CAST(@score as nvarchar(max))
end
go

create procedure Snake.GenerateAchive
as
begin
 declare @achiveX int;
 declare @achiveY int;

 EXEC Snake.RandomX  @output = @achiveX output
 EXEC Snake.RandomY  @output = @achiveY output
 
 update Snake.Field set
	[State] = 2
  where X = @achiveX and Y = @achiveY;
end

go
create procedure Snake.RenderField
as
begin
SET NOCOUNT ON;
	declare @isLost bit = (select top(1) IsLost from Snake.Score order by Id desc)
	if(@isLost = 1)
	begin
	PRINT 'Please, start new game'
	RETURN;
	end
	
	declare @FieldSizeX int = (select max(X) from Snake.Field);
	declare @FieldSizeY int = (select max(Y) from Snake.Field);
	
	declare @countW int = 1;
	declare @countH int =1;
	 
	 while (@countH <= @FieldSizeY)
	 begin
		declare @line nvarchar(max) = '';
		while (@countW <= @FieldSizeX)
		begin
		
			declare @isSnake int = (select COUNT(*) from Snake.Snake s
			where s.X = @countW and s.Y = @countH);
		
			if(@isSnake <> 0)
			begin
				set @line = @line + 'S';
			end
				else
			begin
				declare @state nvarchar(1) = (select 
				 (case [State] 
					when 1 then '`'
					when 2 then '*' 
				 end)
				 From Snake.Field f where f.X = @countW and f.Y = @countH)
				set @line = @line + @state;
			end
			
			set @countW = @countW +1;
		end
		
		PRINT @line;
		set @countH = @countH +1;
		set @countW = 1;
	 end

end
go

create procedure Snake.SetNewSnakeHead(
@newX as int,
@newY as int
)
as
begin
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	
	declare @oldHeadId int = (select Id from  Snake.Snake where IsHead = 1) -- get old head id
	declare @oldScoreId int = (select ScoreId from  Snake.Snake where IsHead = 1)
	
	update Snake.Snake  set IsHead = 0 -- remove head
	
	insert into Snake.Snake (X,Y,IsHead,ParentId,ScoreId) --insert new heaed item
	values(@newX, @newY, 1, null,@oldScoreId)
	
	declare @newSnakeHeadId int = SCOPE_IDENTITY(); -- new head id
	
	update Snake.Snake set ParentId = @newSnakeHeadId -- add relation to new head
	where Id = @oldHeadId
	END TRY
	BEGIN CATCH 
		if @@TRANCOUNT > 0
			rollback transaction;
	END CATCH
	
	if @@TRANCOUNT > 0
		commit;
end
go

create procedure Snake.MoveHead(
@newX as int,
@newY as int
)
as
begin
    --move snake
	With SnakeCTE(SnakeId, snakeX, snakeY, snakeIsHead, PointLevel)
	AS
	(
		select s.Id as SnakeId,X as snakeX,Y as snakeY ,IsHead as snakeY ,1 as PointLevel from Snake.Snake s
		where s.IsHead = 1
		UNION ALL
		select s.Id as SnakeId,X as snakeX,Y as snakeY ,IsHead as snakeY ,PointLevel - 1 as PointLevel from Snake.Snake s
		JOIN SnakeCTE AS sCTE ON s.ParentId = sCTE.SnakeId
	)
	update Snake.Snake
	SET 
		X = CTE2.snakeX,
		Y = CTE2.snakeY
	FROM Snake.Snake AS s
	JOIN SnakeCTE AS sCTE ON s.Id = sCTE.SnakeId
	JOIN SnakeCTE as CTE2 ON CTE2.PointLevel = sCTE.PointLevel + 1
	
	--set new head
	update Snake.Snake set
	X = @newX,
	Y = @newY
	where IsHead = 1
end
go

create procedure Snake.[Go] 
@Direction  as nvarchar(1) --W,A,S,D
as
begin
SET NOCOUNT ON;
	set @Direction = lower(@Direction);

	if( @Direction <> 'w' and
		@Direction <> 'a' and
		@Direction <> 's' and
		@Direction <> 'd')
		RETURN;

	declare @deltaX int = isnull((select 
	case @Direction 
		when 'a' then -1
		when 'd' then 1
	end
	),0)
	
	declare @deltaY int = isnull((select 
	case @Direction 
		when 'w' then -1
		when 's' then 1
	end
	),0)

declare @headX int = (select X from Snake.Snake where IsHead = 1);
declare @headY int = (select Y from Snake.Snake where IsHead = 1);
declare @FieldSizeX int = (select max(X) from Snake.Field);
declare @FieldSizeY int = (select max(Y) from Snake.Field);
declare @NewX int = @headX + @deltaX;
declare @NewY int = @headY + @deltaY;

if( 
   (@NewX NOT BETWEEN 1 AND @FieldSizeX ) OR
   (@NewY NOT BETWEEN 1 AND @FieldSizeY) OR
   (select Count(*) from Snake.Snake where X =@NewX and Y = @NewY and IsHead = 0) > 0
  ) 
 begin
	exec Snake.Lost;
	return;
 end
 
 
 declare @newPositionState int  = 
 (select [State] from Snake.Field  f
 where 
	f.X = @NewX and 
	f.Y = @NewY)
 
if(@newPositionState = 2) --achive detected
begin
	update Snake.Field set [State] = 1 where X = @NewX and Y = @NewY -- remove achive
	EXEC Snake.SetNewSnakeHead @newX = @NewX, @newY = @NewY
	EXEC Snake.GenerateAchive  --add stuff
end
else 
begin
	EXEC Snake.MoveHead @newX = @NewX, @newY = @NewY
end 
 --end logic begin render
 EXEC Snake.RenderField;
END
go

create procedure Snake.ClearGame
as
begin
SET NOCOUNT ON;
    IF OBJECT_ID('Snake.Snake', 'U') IS NOT NULL 
    DROP TABLE Snake.Snake; 

    IF OBJECT_ID('Snake.Score', 'U') IS NOT NULL 
    DROP TABLE Snake.Score; 
    
	IF OBJECT_ID('Snake.Field', 'U') IS NOT NULL 
    DROP TABLE Snake.Field; 
end
go

-- Let me move faster !
--             ____
--            / . .\
--MT          \  ---<
--             \  /
--   __________/ /
---=:___________/
create procedure Snake.CreateIndexes
as
begin
CREATE NONCLUSTERED INDEX SnakeFieldX ON Snake.Field (X);
CREATE NONCLUSTERED INDEX SnakeFieldY ON Snake.Field (Y);
CREATE NONCLUSTERED INDEX SnakeFieldXY ON Snake.Field (X, Y);

CREATE NONCLUSTERED INDEX SnakeSnakeX ON Snake.Snake (X);
CREATE NONCLUSTERED INDEX SnakeSnakeY ON Snake.Snake (Y);
CREATE NONCLUSTERED INDEX SnakeSnakeXY ON Snake.Snake (X, Y);
end
go

create procedure Snake.InitGame
(
@playerName nvarchar(max)
)
as
begin
SET NOCOUNT ON;
	declare @ScoreId int;
	
	EXEC Snake.ClearGame
	EXEC Snake.CreateScoreTable
	EXEC Snake.InitName @playerName, @UserId = @ScoreId out
	EXEC Snake.CreateField @width = 15, @height = 15
	EXEC Snake.CreateSnake @ScoreId, @StartX = 7, @StartY = 7
	EXEC Snake.CreateIndexes
	EXEC Snake.GenerateAchive
	EXEC Snake.RenderField
end
