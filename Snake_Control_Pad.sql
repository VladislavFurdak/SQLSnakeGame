--   _________         _________
--  /         \       /         \   Normand
-- /  /~~~~~\  \     /  /~~~~~\  \  Veilleux
-- |  |     |  |     |  |     |  |
-- |  |     |  |     |  |     |  |
-- |  |     |  |     |  |     |  |         /
-- |  |     |  |     |  |     |  |       //
--(o  o)    \  \_____/  /     \  \_____/ /
-- \__/      \         /       \        /
--  |         ~~~~~~~~~         ~~~~~~~~
--  ^ T-SQL Snake v 1.0 
--[ON/OFF]
  USE SnakeDB
--Start Pay / Play again-----------------
		EXEC Snake.InitGame	'Name'
-------------[CONTROL PAD] --------------|
		EXEC Snake.[Go]'W'			   --|
EXEC Snake.[Go]'A'	EXEC Snake.[Go]'D' --|
		EXEC Snake.[Go]'S'			   --|
------------------------------------------
--Select a command and press F5
--2016 author: Vladislav Furdak