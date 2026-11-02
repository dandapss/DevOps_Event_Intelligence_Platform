2nd. November 2026
Still architecting about DB usage thinking about further operation.
PostgreSQL.yaml might be able to create DB itself, and I was thinking to use init.sql to create the table. But there are few issues about init.sql failure, adding/deleting columes etc. 
If I use Flyway/Alembic Migration to prevent those issues, then it might be clear end but I am setting short deadline term and those are too much to study and apply. 
Try to set everything initially using init.sql and think about upgrading when everything is finished. It might be good point of next challenge. 
